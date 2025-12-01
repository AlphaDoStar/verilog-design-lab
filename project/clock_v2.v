module clock (
    input wire clock, reset,
    input wire [6:0] mode,
    input wire [11:0] button,
    output wire E, RS, RW,
    output wire [7:0] DATA, LED,
    output wire piezo
);
    wire [11:0] button_t;

    reg [9:0] count;

    reg [3:0] country;
    reg [4:0] hour;
    reg [5:0] minute, second;
    reg mode_12_24;

    reg [4:0] alarm_hour;
    reg [5:0] alarm_minute;
    reg alarm_enabled;

    // 멜로디 녹음/재생
    reg [7:0] melody[0:79];     // 8초 * 10샘플/초 = 80 샘플
    reg [6:0] melody_length;    // 0~79
    reg [6:0] record_idx;       // 녹음 인덱스
    reg [6:0] play_idx;         // 재생 인덱스
    reg [6:0] sample_count;     // 100ms 카운터 (0~99)
    reg playing;                // 재생 중 플래그
    reg alarm_triggered;        // 알람 울림 플래그

    wire record_mode = mode[3];
    wire [7:0] melody_led = (melody_length >= 70) ? 8'b11111111 :
                            (melody_length >= 60) ? 8'b01111111 :
                            (melody_length >= 50) ? 8'b00111111 :
                            (melody_length >= 40) ? 8'b00011111 :
                            (melody_length >= 30) ? 8'b00001111 :
                            (melody_length >= 20) ? 8'b00000111 :
                            (melody_length >= 10) ? 8'b00000011 :
                            (melody_length > 0)   ? 8'b00000001 : 8'b00000000;

    assign LED = record_mode ? melody_led : {7'b0000_000, alarm_enabled};

    wire [7:0] current_melody = playing ? melody[play_idx] : 8'b00000000;

    one_shot_trigger #(.WIDTH(12)) ost1 (clock, reset, button, button_t);
    
    lcd_display ld1 (
        .clock(clock), 
        .reset(reset), 
        .mode(mode),
        .country(country), 
        .hour(hour), 
        .minute(minute), 
        .second(second),
        .alarm_hour(alarm_hour),
        .alarm_minute(alarm_minute),
        .alarm_enabled(alarm_enabled),
        .mode_12_24(mode_12_24), 
        .E(E), 
        .RS(RS), 
        .RW(RW), 
        .DATA(DATA)
    );

    piezo_player pp1 (
        .clock(clock),
        .reset(reset),
        .button(current_melody),
        .piezo(piezo)
    );

    integer i;
    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            count <= 0;
            country <= 4'h0;
            hour <= 0;
            minute <= 0;
            second <= 0;
            mode_12_24 <= 0;
            alarm_hour <= 0;
            alarm_minute <= 0;
            alarm_enabled <= 0;
            melody_length <= 0;
            record_idx <= 0;
            play_idx <= 0;
            sample_count <= 0;
            playing <= 0;
            alarm_triggered <= 0;
            for (i = 0; i < 80; i = i + 1) begin
                melody[i] <= 8'b00000000;
            end
        end
        else begin
            // 재생 로직
            if (playing) begin
                sample_count <= sample_count + 1;
                if (sample_count == 99) begin  // 100ms 경과
                    sample_count <= 0;
                    if (play_idx >= melody_length - 1) begin
                        playing <= 0;
                        play_idx <= 0;
                        alarm_triggered <= 0;
                    end
                    else begin
                        play_idx <= play_idx + 1;
                    end
                end
            end

            // 알람 체크 (일반 모드일 때만)
            if (!record_mode && alarm_enabled && !alarm_triggered && !playing) begin
                if (hour == alarm_hour && minute == alarm_minute && second == 0) begin
                    if (melody_length > 0) begin
                        playing <= 1;
                        play_idx <= 0;
                        sample_count <= 0;
                        alarm_triggered <= 1;
                    end
                end
            end

            // 알람이 지난 후 1초가 지나면 alarm_triggered 해제
            if (alarm_triggered && (second != 0)) begin
                alarm_triggered <= 0;
            end

            casez (mode)
                7'b1??????: begin  // 시간 설정 모드
                    case (button_t)
                        12'b1000_0000_0000: hour <= (hour == 0) ? 23 : hour - 1;
                        12'b0010_0000_0000: hour <= (hour == 23) ? 0 : hour + 1;
                        12'b0001_0000_0000: minute <= (minute == 0) ? 59 : minute - 1;
                        12'b0000_0100_0000: minute <= (minute == 59) ? 0 : minute + 1;
                        12'b0000_0010_0000: second <= (second == 0) ? 59 : second - 1;
                        12'b0000_0000_1000: second <= (second == 59) ? 0 : second + 1;
                        12'b0000_0000_0010: mode_12_24 <= !mode_12_24;
                    endcase
                end
                7'b01?????: begin  // 국가 선택 모드
                    case (button_t)
                        12'b1000_0000_0000: country <= 4'h0;
                        12'b0100_0000_0000: country <= 4'h1;
                        12'b0010_0000_0000: country <= 4'h2;
                    endcase
                end
                7'b001????: begin  // 알람 설정 모드
                    case (button_t)
                        12'b1000_0000_0000: alarm_hour <= (alarm_hour == 0) ? 23 : alarm_hour - 1;
                        12'b0010_0000_0000: alarm_hour <= (alarm_hour == 23) ? 0 : alarm_hour + 1;
                        12'b0001_0000_0000: alarm_minute <= (alarm_minute == 0) ? 59 : alarm_minute - 1;
                        12'b0000_0100_0000: alarm_minute <= (alarm_minute == 59) ? 0 : alarm_minute + 1;
                        12'b0000_0000_0001: alarm_enabled <= !alarm_enabled;
                    endcase
                end
                7'b0001???: begin  // 녹음 모드
                    // 재생 버튼 (버튼 11)
                    if (button_t[11]) begin
                        if (melody_length > 0 && !playing) begin
                            playing <= 1;
                            play_idx <= 0;
                            sample_count <= 0;
                        end
                    end
                    // 녹음 (버튼 0-7)
                    else if (|button_t[7:0] && melody_length < 80) begin
                        sample_count <= sample_count + 1;
                        if (sample_count == 99) begin  // 100ms마다 샘플링
                            sample_count <= 0;
                            melody[melody_length] <= button[7:0];  // button_t 아닌 button 사용
                            melody_length <= melody_length + 1;
                        end
                    end
                    else begin
                        sample_count <= 0;
                    end
                    
                    // 리셋 버튼 (버튼 10)
                    if (button_t[10]) begin
                        melody_length <= 0;
                        record_idx <= 0;
                        for (i = 0; i < 80; i = i + 1) begin
                            melody[i] <= 8'b00000000;
                        end
                    end
                end
                default: begin  // 일반 동작 모드
                    count <= count + 1;
                    if (count == 999) begin
                        count <= 0;
                        second <= second + 1;
                        
                        if (second == 59) begin
                            second <= 0;
                            minute <= minute + 1;

                            if (minute == 59) begin
                                minute <= 0;
                                hour <= (hour == 23) ? 0 : hour + 1;
                            end
                        end
                    end
                end
            endcase
        end
    end
endmodule

module piezo_player (
    input wire clock, reset,
    input wire [7:0] button,
    output reg piezo
);
    localparam C2 = 12'd3830;
    localparam D2 = 12'd3400;
    localparam E2 = 12'd3038;
    localparam F2 = 12'd2864;
    localparam G2 = 12'd2550;
    localparam A2 = 12'd2272;
    localparam B2 = 12'd2028;
    localparam C3 = 12'd1912;

    reg [11:0] cnt, lim;

    always @(*) begin
        if (!reset) lim = 12'd0;
        else begin
            casez (button)
                8'b00000001: lim = C2;
                8'b0000001?: lim = D2;
                8'b000001??: lim = E2;
                8'b00001???: lim = F2;
                8'b0001????: lim = G2;
                8'b001?????: lim = A2;
                8'b01??????: lim = B2;
                8'b1???????: lim = C3;
                default: lim = 12'd0;
            endcase
        end
    end

    always @(posedge clock or negedge reset) begin
        if (!reset || !lim) begin
            piezo <= 0;
            cnt <= 0;
        end
        else if (cnt >= lim / 2) begin
            piezo <= ~piezo;
            cnt <= 0;
        end
        else cnt <= cnt + 1;
    end
endmodule