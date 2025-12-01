module clock (
    input wire main_clock,
    input wire reset,
    input wire [6:0] mode,
    input wire [11:0] button,
    output wire E, RS, RW,
    output wire [7:0] DATA,
    output reg [7:0] LED,
    output wire PIEZO
);
    wire [11:0] button_t;

    reg [9:0] clock_div;
    reg slow_clock;

    always @(posedge main_clock or negedge reset) begin
        if (!reset) begin
            clock_div <= 0;
            slow_clock <= 0;
        end
        else begin
            if (clock_div == 499) begin
                clock_div <= 0;
                slow_clock <= ~slow_clock;
            end
            else begin
                clock_div <= clock_div + 1;
            end
        end
    end

    reg [9:0] count;

    reg [3:0] country;
    reg [4:0] hour;
    reg [5:0] minute, second;
    reg mode_12_24;

    reg [4:0] alarm_hour;
    reg [5:0] alarm_minute;
    reg alarm_enabled;

    wire record_mode = mode[3];
    wire alarm_trigger;
    wire [7:0] piezo_button;

    one_shot_trigger #(.WIDTH(12)) ost1 (slow_clock, reset, button, button_t);
    
    lcd_display ld1 (
        .clock(slow_clock),
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

    alarm_recorder ar1 (
        .clock(slow_clock),
        .reset(reset),
        .record_mode(record_mode),
        .button(button),
        .button_t(button_t),
        .alarm_trigger(alarm_trigger),
        .piezo_button(piezo_button),
        .melody_led(LED)
    );

    piezo_player pp1 (
        .clock(main_clock),
        .reset(reset),
        .button(piezo_button),
        .PIEZO(PIEZO)
    );

    assign alarm_trigger = alarm_enabled && 
                          (hour == alarm_hour) && 
                          (minute == alarm_minute) && 
                          (second == 0);

    integer i;
    always @(posedge slow_clock or negedge reset) begin
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
        end
        else begin
            if (!record_mode) begin
                LED <= {7'b0000_000, alarm_enabled};
            end

            casez (mode)
                7'b1??????: begin
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
                7'b01?????: begin
                    case (button_t)
                        12'b1000_0000_0000: country <= 4'h0;
                        12'b0100_0000_0000: country <= 4'h1;
                        12'b0010_0000_0000: country <= 4'h2;
                    endcase
                end
                7'b001????: begin
                    case (button_t)
                        12'b1000_0000_0000: alarm_hour <= (alarm_hour == 0) ? 23 : alarm_hour - 1;
                        12'b0010_0000_0000: alarm_hour <= (alarm_hour == 23) ? 0 : alarm_hour + 1;
                        12'b0001_0000_0000: alarm_minute <= (alarm_minute == 0) ? 59 : alarm_minute - 1;
                        12'b0000_0100_0000: alarm_minute <= (alarm_minute == 59) ? 0 : alarm_minute + 1;
                        12'b0000_0000_0010: alarm_enabled <= !alarm_enabled;
                    endcase
                end
                default: begin
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

module alarm_recorder (
    input wire clock, reset,
    input wire record_mode,
    input wire [7:0] button,
    input wire [11:0] button_t,
    input wire alarm_trigger,
    output reg [7:0] piezo_button,
    output reg [7:0] melody_led
);
    reg [7:0] melody[0:7999];
    reg [12:0] melody_length;
    reg [12:0] play_index;
    reg playing;
    reg alarm_triggered;

    integer i;

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            melody_length <= 0;
            play_index <= 0;
            playing <= 0;
            alarm_triggered <= 0;
            piezo_button <= 8'b00000000;
            melody_led <= 8'b00000000;
            for (i = 0; i < 8000; i = i + 1) begin
                melody[i] <= 8'b00000000;
            end
        end
        else begin
            if (record_mode) piezo_button <= button;
            else if (playing) piezo_button <= melody[play_index];
            else piezo_button <= 8'b00000000;

            if (record_mode) begin
                if (melody_length < 8000) begin
                    melody[melody_length] <= button;
                    melody_length <= melody_length + 1;
                end
                else begin
                    if (button_t[9] && !playing && melody_length > 0) begin
                        play_index <= 0;
                        playing <= 1;
                    end

                    if (button_t[11]) begin
                        melody_length <= 0;
                        play_index <= 0;
                        playing <= 0;
                        for (i = 0; i < 8000; i = i + 1) begin
                            melody[i] <= 8'b00000000;
                        end
                    end
                end

                if (melody_length >= 7000) melody_led <= 8'b1111_1111;
                else if (melody_length >= 6000) melody_led <= 8'b1111_1110;
                else if (melody_length >= 5000) melody_led <= 8'b1111_1100;
                else if (melody_length >= 4000) melody_led <= 8'b1111_1000;
                else if (melody_length >= 3000) melody_led <= 8'b1111_0000;
                else if (melody_length >= 2000) melody_led <= 8'b1110_0000;
                else if (melody_length >= 1000) melody_led <= 8'b1100_0000;
                else if (melody_length > 0) melody_led <= 8'1000_0000;
                else melody_led <= 8'b0000_0000;
            end

            if (playing) begin
                if (play_index >= melody_length - 1) begin
                    playing <= 0;
                    play_index <= 0;
                    alarm_triggered <= 0;
                end
                else play_index <= play_index + 1;
            end

            if (alarm_trigger && !alarm_triggered && !playing && melody_length > 0) begin
                play_index <= 0;
                playing <= 1;
                alarm_triggered <= 1;
            end

            if (alarm_triggered && !alarm_trigger) alarm_triggered <= 0;
        end
    end
endmodule

module one_shot_trigger #(parameter WIDTH = 1)(
    input wire clock, reset,
    input wire [WIDTH-1:0] i,
    output reg [WIDTH-1:0] o
);
    reg [WIDTH-1:0] r;

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            r <= {WIDTH{1'b0}};
            o <= {WIDTH{1'b0}};
        end
        else begin
            r <= i;
            o <= i & ~r;
        end
    end
endmodule

module lcd_display (
    input wire clock, reset,
    input wire [6:0] mode,
    input wire [3:0] country,
    input wire [4:0] hour, alarm_hour,
    input wire [5:0] minute, alarm_minute, second,
    input wire alarm_enabled,
    input wire mode_12_24,
    output wire E,
    output reg RS, RW,
    output reg [7:0] DATA, LED
);
    localparam DELAY = 3'b000;
    localparam FUNCTION_SET = 3'b001;
    localparam DISP_ONOFF = 3'b010;
    localparam ENTRY_MODE = 3'b011;
    localparam WRITE = 3'b100;
    localparam DELAY_T = 3'b101;
    localparam CURSOR_AT_HOME = 3'b110;
    localparam CLEAR_DISP = 3'b111;

    function [23:0] get_contry_name;
        input [3:0] country;
        begin
            case (country)
                4'h0: get_contry_name = {8'h4A, 8'h50, 8'h4E};  // JPN
                4'h1: get_contry_name = {8'h43, 8'h48, 8'h4E};  // CHN
                4'h2: get_contry_name = {8'h55, 8'h53, 8'h41};  // USA
                default: get_contry_name = {8'h4B, 8'h4F, 8'h52};  // KOR
            endcase
        end
    endfunction

    function [4:0] get_foreign_hour;
        input [3:0] country;
        input [4:0] hour;
        begin
            case (country)
                4'h0: get_foreign_hour = hour;
                4'h1: get_foreign_hour = (hour - 1 + 24) % 24;
                4'h2: get_foreign_hour = (hour - 14 + 24) % 24;
                default: get_foreign_hour = hour;
            endcase
        end
    endfunction

    function [4:0] get_hour_display;
        input mode_12_24;
        input [4:0] hour;
        begin
            if (mode_12_24) begin
                if (hour == 0) get_hour_display = 5'd12;
                else if (hour > 12) get_hour_display = hour - 5'd12;
                else get_hour_display = hour;
            end
            else get_hour_display = hour;
        end
    endfunction

    function [15:0] get_am_pm;
        input mode_12_24;
        input [4:0] hour;
        begin
            if (mode_12_24) begin
                if (hour < 12) get_am_pm = {8'h41, 8'h4D}; // AM
                else get_am_pm = {8'h50, 8'h4D}; // PM
            end
            else get_am_pm = {8'h20, 8'h20}; // 
        end
    endfunction

    wire [4:0] hour_display = get_hour_display(mode_12_24, hour);
    wire [15:0] am_pm = get_am_pm(mode_12_24, hour);

    wire [23:0] foreign_country_name = get_contry_name(country);
    wire [4:0] foreign_hour = get_foreign_hour(country, hour);
    wire [4:0] foreign_hour_display = get_hour_display(mode_12_24, foreign_hour);
    wire [15:0] foreign_am_pm = get_am_pm(mode_12_24, foreign_hour);

    wire [4:0] alarm_hour_display = get_hour_display(mode_12_24, alarm_hour);
    wire [15:0] alarm_am_pm = get_am_pm(mode_12_24, alarm_hour);

    reg [6:0] count;
    reg [2:0] state;

    reg [6:0] prev_mode;
    reg [3:0] prev_country;
    reg [4:0] prev_hour, prev_alarm_hour;
    reg [5:0] prev_minute, prev_alarm_minute, prev_second;
    reg prev_alarm_enabled, prev_mode_12_24;

    wire input_changed = (mode != prev_mode) ||
                         (country != prev_country) ||
                         (hour != prev_hour) ||
                         (alarm_hour != prev_alarm_hour) ||
                         (minute != prev_minute) ||
                         (alarm_minute != prev_alarm_minute) ||
                         (second != prev_second) ||
                         (alarm_enabled != prev_alarm_enabled) ||
                         (mode_12_24 != prev_mode_12_24);

    assign E = clock;

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            count <= 0;
            state <= DELAY;
            prev_mode <= 0;
            prev_country <= 0;
            prev_hour <= 0;
            prev_alarm_hour <= 0;
            prev_minute <= 0;
            prev_alarm_minute <= 0;
            prev_second <= 0;
            prev_alarm_enabled <= 0;
            prev_mode_12_24 <= 0;
            LED <= 0;
        end
        else begin
            count <= count + 1;
            prev_mode <= mode;
            prev_country <= country;
            prev_hour <= hour;
            prev_alarm_hour <= alarm_hour;
            prev_minute <= minute;
            prev_alarm_minute <= alarm_minute;
            prev_second <= second;
            prev_alarm_enabled <= alarm_enabled;
            prev_mode_12_24 <= mode_12_24;

            case (state)
                DELAY: begin
                    if (count >= 70) begin
                        count <= 0;
                        state <= FUNCTION_SET;
                    end
                end
                FUNCTION_SET: begin
                    if (count >= 30) begin
                        count <= 0;
                        state <= DISP_ONOFF;
                    end
                end
                DISP_ONOFF: begin
                    if (count >= 30) begin
                        count <= 0;
                        state <= ENTRY_MODE;
                    end
                end
                ENTRY_MODE: begin
                    if (count >= 30) begin
                        count <= 0;
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    if (count >= 40) begin
                        count <= 0;
                        state <= DELAY_T;
                    end
                end
                DELAY_T: begin
                    count <= 0;
                    if (input_changed) begin
                        state <= CURSOR_AT_HOME;
                    end
                end
                CURSOR_AT_HOME: begin
                    if (count >= 5) begin
                        count <= 0;
                        state <= CLEAR_DISP;
                    end
                end
                CLEAR_DISP: begin
                    if (count >= 5) begin
                        count <= 0;
                        state <= WRITE;
                    end
                end
            endcase
        end
    end

    always @(posedge clock or negedge reset) begin
        if (!reset) {RS, RW, DATA} <= 10'b00_0011_0000;
        else begin
            case (state)
                DELAY: {RS, RW, DATA} <= 10'b11_0000_0000;
                FUNCTION_SET: {RS, RW, DATA} <= 10'b00_0011_1000;
                DISP_ONOFF: {RS, RW, DATA} <= 10'b00_0000_1100;
                ENTRY_MODE: {RS, RW, DATA} <= 10'b00_0000_0110;
                WRITE: begin
                    casez (mode)
                        7'b001????: begin
                            case (count)
                                00: {RS, RW, DATA} <= 10'b00_1000_0000;
                                01: {RS, RW, DATA} <= {2'b10, 8'h41}; // A
                                02: {RS, RW, DATA} <= {2'b10, 8'h4C}; // L
                                03: {RS, RW, DATA} <= {2'b10, 8'h41}; // A
                                04: {RS, RW, DATA} <= {2'b10, 8'h52}; // R
                                05: {RS, RW, DATA} <= {2'b10, 8'h4D}; // M
                                06: {RS, RW, DATA} <= 10'b10_0010_0000;
                                07: {RS, RW, DATA} <= 10'b10_0011_0000 + (alarm_hour_display / 10);
                                08: {RS, RW, DATA} <= 10'b10_0011_0000 + (alarm_hour_display % 10);
                                09: {RS, RW, DATA} <= {2'b10, 8'h3A}; // :
                                10: {RS, RW, DATA} <= 10'b10_0011_0000 + (alarm_minute / 10);
                                11: {RS, RW, DATA} <= 10'b10_0011_0000 + (alarm_minute % 10);
                                12: {RS, RW, DATA} <= 10'b10_0010_0000;
                                13: {RS, RW, DATA} <= {2'b10, alarm_am_pm[15:8]};
                                14: {RS, RW, DATA} <= {2'b10, alarm_am_pm[7:0]};

                                15: {RS, RW, DATA} <= 10'b00_1100_0000;
                                16: {RS, RW, DATA} <= {2'b10, 8'h53}; // S
                                17: {RS, RW, DATA} <= {2'b10, 8'h74}; // t
                                18: {RS, RW, DATA} <= {2'b10, 8'h61}; // a
                                19: {RS, RW, DATA} <= {2'b10, 8'h74}; // t
                                20: {RS, RW, DATA} <= {2'b10, 8'h75}; // u
                                21: {RS, RW, DATA} <= {2'b10, 8'h73}; // s
                                22: {RS, RW, DATA} <= {2'b10, 8'h3A}; // :
                                23: {RS, RW, DATA} <= 10'b10_0010_0000;
                                24: {RS, RW, DATA} <= alarm_enabled ? {2'b10, 8'h4F} : {2'b10, 8'h4F}; // O
                                25: {RS, RW, DATA} <= alarm_enabled ? {2'b10, 8'h4E} : {2'b10, 8'h46}; // N / FF
                                26: {RS, RW, DATA} <= alarm_enabled ? 10'b10_0010_0000 : {2'b10, 8'h46}; //   / F

                                default: {RS, RW, DATA} <= 10'b11_0000_0000;
                            endcase
                        end
                        default: begin
                            case (count)
                                00: {RS, RW, DATA} <= 10'b00_1000_0000;
                                01: {RS, RW, DATA} <= {2'b10, 8'h4B}; // K
                                02: {RS, RW, DATA} <= {2'b10, 8'h4F}; // O
                                03: {RS, RW, DATA} <= {2'b10, 8'h52}; // R
                                04: {RS, RW, DATA} <= 10'b10_0010_0000;
                                05: {RS, RW, DATA} <= 10'b10_0011_0000 + (hour_display / 10);
                                06: {RS, RW, DATA} <= 10'b10_0011_0000 + (hour_display % 10);
                                07: {RS, RW, DATA} <= {2'b10, 8'h3A}; // :
                                08: {RS, RW, DATA} <= 10'b10_0011_0000 + (minute / 10);
                                09: {RS, RW, DATA} <= 10'b10_0011_0000 + (minute % 10);
                                10: {RS, RW, DATA} <= {2'b10, 8'h3A}; // :
                                11: {RS, RW, DATA} <= 10'b10_0011_0000 + (second / 10);
                                12: {RS, RW, DATA} <= 10'b10_0011_0000 + (second % 10);
                                13: {RS, RW, DATA} <= 10'b10_0010_0000;
                                14: {RS, RW, DATA} <= {2'b10, am_pm[15:8]};
                                15: {RS, RW, DATA} <= {2'b10, am_pm[7:0]};

                                16: {RS, RW, DATA} <= 10'b00_1100_0000;
                                17: {RS, RW, DATA} <= {2'b10, foreign_country_name[23:16]};
                                18: {RS, RW, DATA} <= {2'b10, foreign_country_name[15:8]};
                                19: {RS, RW, DATA} <= {2'b10, foreign_country_name[7:0]};
                                20: {RS, RW, DATA} <= 10'b10_0010_0000;
                                21: {RS, RW, DATA} <= 10'b10_0011_0000 + (foreign_hour_display / 10);
                                22: {RS, RW, DATA} <= 10'b10_0011_0000 + (foreign_hour_display % 10);
                                23: {RS, RW, DATA} <= {2'b10, 8'h3A}; // :
                                24: {RS, RW, DATA} <= 10'b10_0011_0000 + (minute / 10);
                                25: {RS, RW, DATA} <= 10'b10_0011_0000 + (minute % 10);
                                26: {RS, RW, DATA} <= {2'b10, 8'h3A}; // :
                                27: {RS, RW, DATA} <= 10'b10_0011_0000 + (second / 10);
                                28: {RS, RW, DATA} <= 10'b10_0011_0000 + (second % 10);
                                29: {RS, RW, DATA} <= 10'b10_0010_0000;
                                30: {RS, RW, DATA} <= {2'b10, foreign_am_pm[15:8]};
                                31: {RS, RW, DATA} <= {2'b10, foreign_am_pm[7:0]};

                                default: {RS, RW, DATA} <= 10'b11_0000_0000;
                            endcase
                        end
                    endcase
                end
                DELAY_T: {RS, RW, DATA} <= 10'b11_0000_0000;
                CURSOR_AT_HOME: {RS, RW, DATA} <= 10'b00_0000_0010;
                CLEAR_DISP: {RS, RW, DATA} <= 10'b00_0000_0001;
            endcase
        end
    end
endmodule

module piezo_player (
    input wire clock, reset,
    input wire [7:0] button,
    output reg PIEZO
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
                8'b1???????: lim = C2;
                8'b01??????: lim = D2;
                8'b001?????: lim = E2;
                8'b0001????: lim = F2;
                8'b00001???: lim = G2;
                8'b000001??: lim = A2;
                8'b0000001?: lim = B2;
                8'b00000001: lim = C3;
                default: lim = 12'd0;
            endcase
        end
    end

    always @(posedge clock or negedge reset) begin
        if (!reset || !lim) begin
            PIEZO <= 0;
            cnt <= 0;
        end
        else if (cnt >= lim / 2) begin
            PIEZO <= ~PIEZO;
            cnt <= 0;
        end
        else cnt <= cnt + 1;
    end
endmodule
