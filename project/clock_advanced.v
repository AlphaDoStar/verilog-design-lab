module clock (
    input wire clock, reset,
    input wire [6:0] mode,
    input wire [11:0] button,
    output wire E, RS, RW,
    output wire [7:0] DATA, LED,
    output wire PIEZO
);
    reg [8:0] clock_div;
    reg slow_clock;

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            clock_div <= 0;
            slow_clock <= 0;
        end
        else begin
            if (clock_div >= 499) begin
                clock_div <= 0;
                slow_clock <= ~slow_clock;
            end
            else clock_div <= clock_div + 1;
        end
    end

    reg [9:0] count, timer_count;
    reg [3:0] country;

    reg [4:0] hour, alarm_hour;
    reg [5:0] minute, alarm_minute, timer_minute;
    reg [5:0] second, timer_second;

    reg alarm_enabled, timer_started, mode_12_24;

    wire [11:0] button_t;
    wire [7:0] recording_led;
    wire [3:0] note;

    wire alarm =
        (alarm_enabled && (hour == alarm_hour) && (minute == alarm_minute) && (second == 0)) ||
        (timer_started && (timer_minute == 0) && (timer_second == 0));

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
        .timer_minute(timer_minute),
        .timer_second(timer_second),
        .timer_started(timer_started),
        .mode_12_24(mode_12_24),
        .E(E),
        .RS(RS),
        .RW(RW),
        .DATA(DATA)
    );
    
    alarm_recorder ar1 (slow_clock, reset, mode, button, button_t, alarm, timer_started, note, recording_led);
    piezo_player pp1 (clock, reset, note, PIEZO);

    assign LED = ((mode & 7'b0000100) != 0) ? recording_led : {7'b0000_000, alarm_enabled};

    always @(posedge slow_clock or negedge reset) begin
        if (!reset) begin
            count <= 0;
            timer_count <= 0;
            country <= 4'h0;
            hour <= 0;
            alarm_hour <= 0;
            minute <= 0;
            alarm_minute <= 0;
            timer_minute <= 0;
            second <= 0;
            timer_second <= 0;
            alarm_enabled <= 0;
            timer_started <= 0;
            mode_12_24 <= 0;
        end
        else begin
            case (mode)
                7'b1000000: begin
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
                7'b0100000: begin
                    case (button_t)
                        12'b1000_0000_0000: country <= 4'h0;
                        12'b0100_0000_0000: country <= 4'h1;
                        12'b0010_0000_0000: country <= 4'h2;
                    endcase
                end
                7'b0010000: begin
                    case (button_t)
                        12'b1000_0000_0000: alarm_hour <= (alarm_hour == 0) ? 23 : alarm_hour - 1;
                        12'b0010_0000_0000: alarm_hour <= (alarm_hour == 23) ? 0 : alarm_hour + 1;
                        12'b0001_0000_0000: alarm_minute <= (alarm_minute == 0) ? 59 : alarm_minute - 1;
                        12'b0000_0100_0000: alarm_minute <= (alarm_minute == 59) ? 0 : alarm_minute + 1;
                        12'b0000_0000_0010: alarm_enabled <= ~alarm_enabled;
                    endcase
                end
                7'b0001000: begin
                    if (timer_started) begin
                        timer_count <= timer_count + 1;

                        if (timer_count === 999) begin
                            timer_count <= 0;
                            timer_second <= timer_second - 1;

                            if (timer_second == 0) begin
                                timer_second <= 59;
                                timer_minute <= timer_minute - 1;

                                if (timer_minute == 0) begin
                                    timer_second <= 0;
                                    timer_minute <= 0;
                                end
                            end
                        end
                    end

                    case (button_t)
                        12'b1000_0000_0000: timer_minute <= (timer_minute == 0) ? 59 : timer_minute - 1;
                        12'b0010_0000_0000: timer_minute <= (timer_minute == 59) ? 0 : timer_minute + 1;
                        12'b0001_0000_0000: timer_second <= (timer_second == 0) ? 59 : timer_second - 1;
                        12'b0000_0100_0000: timer_second <= (timer_second == 59) ? 0 : timer_second + 1;
                        12'b0000_0000_0010: timer_started <= ~timer_started;
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

module lcd_display (
    input wire clock, reset,
    input wire [6:0] mode,
    input wire [3:0] country,
    input wire [4:0] hour, alarm_hour,
    input wire [5:0] minute, alarm_minute, timer_minute,
    input wire [5:0] second, timer_second,
    input wire alarm_enabled, timer_started, mode_12_24,
    output wire E,
    output reg RS, RW,
    output reg [7:0] DATA
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
    reg [5:0] prev_minute, prev_alarm_minute, prev_timer_minute;
    reg [5:0] prev_second, prev_timer_second;
    reg prev_alarm_enabled, prev_timer_started, prev_mode_12_24;

    wire input_changed = (mode != prev_mode) ||
                         (country != prev_country) ||
                         (hour != prev_hour) ||
                         (alarm_hour != prev_alarm_hour) ||
                         (minute != prev_minute) ||
                         (alarm_minute != prev_alarm_minute) ||
                         (timer_minute != prev_timer_minute) ||
                         (second != prev_second) ||
                         (timer_second != prev_timer_second) ||
                         (alarm_enabled != prev_alarm_enabled) ||
                         (timer_started != prev_timer_started) ||
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
            prev_timer_minute <= 0;
            prev_second <= 0;
            prev_timer_second <= 0;
            prev_alarm_enabled <= 0;
            prev_timer_started <= 0;
            prev_mode_12_24 <= 0;
        end
        else begin
            count <= count + 1;
            prev_mode <= mode;
            prev_country <= country;
            prev_hour <= hour;
            prev_alarm_hour <= alarm_hour;
            prev_minute <= minute;
            prev_alarm_minute <= alarm_minute;
            prev_timer_minute <= timer_minute;
            prev_second <= second;
            prev_timer_second <= timer_second;
            prev_alarm_enabled <= alarm_enabled;
            prev_timer_started <= timer_started;
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
                    case (mode)
                        7'b0010000: begin
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
                                25: {RS, RW, DATA} <= alarm_enabled ? {2'b10, 8'h4E} : {2'b10, 8'h46}; // N / F
                                26: {RS, RW, DATA} <= alarm_enabled ? 10'b10_0010_0000 : {2'b10, 8'h46}; // / F

                                default: {RS, RW, DATA} <= 10'b11_0000_0000;
                            endcase
                        end
                        7'b0001000: begin
                            case (count)
                                00: {RS, RW, DATA} <= 10'b00_1000_0000;
                                01: {RS, RW, DATA} <= {2'b10, 8'h54}; // T
                                02: {RS, RW, DATA} <= {2'b10, 8'h49}; // I
                                03: {RS, RW, DATA} <= {2'b10, 8'h4D}; // M
                                04: {RS, RW, DATA} <= {2'b10, 8'h45}; // E
                                05: {RS, RW, DATA} <= {2'b10, 8'h52}; // R
                                06: {RS, RW, DATA} <= 10'b10_0010_0000;
                                07: {RS, RW, DATA} <= 10'b10_0011_0000 + (timer_minute / 10);
                                08: {RS, RW, DATA} <= 10'b10_0011_0000 + (timer_minute % 10);
                                09: {RS, RW, DATA} <= {2'b10, 8'h3A}; // :
                                10: {RS, RW, DATA} <= 10'b10_0011_0000 + (timer_second / 10);
                                11: {RS, RW, DATA} <= 10'b10_0011_0000 + (timer_second % 10);

                                12: {RS, RW, DATA} <= 10'b00_1100_0000;
                                13: {RS, RW, DATA} <= {2'b10, 8'h53}; // S
                                14: {RS, RW, DATA} <= {2'b10, 8'h74}; // t
                                15: {RS, RW, DATA} <= {2'b10, 8'h61}; // a
                                16: {RS, RW, DATA} <= {2'b10, 8'h74}; // t
                                17: {RS, RW, DATA} <= {2'b10, 8'h75}; // u
                                18: {RS, RW, DATA} <= {2'b10, 8'h73}; // s
                                19: {RS, RW, DATA} <= {2'b10, 8'h3A}; // :
                                20: {RS, RW, DATA} <= 10'b10_0010_0000;
                                21: {RS, RW, DATA} <= timer_started ? {2'b10, 8'h52} : {2'b10, 8'h53}; // R / S
                                22: {RS, RW, DATA} <= timer_started ? {2'b10, 8'h55} : {2'b10, 8'h54}; // U / T
                                23: {RS, RW, DATA} <= timer_started ? {2'b10, 8'h4E} : {2'b10, 8'h4F}; // N / O
                                24: {RS, RW, DATA} <= timer_started ? 10'b10_0010_0000 : {2'b10, 8'h50}; // / P

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

module alarm_recorder (
    input wire clock, reset,
    input wire [6:0] mode,
    input wire [11:0] button, button_t,
    input wire alarm, timer_started,
    output reg [3:0] note,
    output reg [7:0] recording_led
);
    reg [3:0] melody [63:0];
    reg [5:0] melody_index, playing_index, index;

    reg playing;
    reg [6:0] count;

    wire alarm_t;
    wire timer_mode = (mode & 7'b0001000) != 0;
    wire recording_mode = (mode & 7'b0000100) != 0;

    one_shot_trigger #(.WIDTH(1)) ost1 (clock, reset, alarm, alarm_t);
    
    initial begin
        melody[0] <= 4'd8;
        melody[1] <= 4'd0;
        melody[2] <= 4'd8;
        melody[3] <= 4'd0;
        melody[4] <= 4'd8;
        melody[5] <= 4'd0;
        melody[6] <= 4'd8;
        melody[7] <= 4'd0;
        melody[8] <= 4'd0;
        melody[9] <= 4'd0;
        melody[10] <= 4'd0;
        melody[11] <= 4'd0;
        melody[12] <= 4'd0;
        melody[13] <= 4'd0;
        melody[14] <= 4'd0;
        melody[15] <= 4'd0;
        melody[16] <= 4'd8;
        melody[17] <= 4'd0;
        melody[18] <= 4'd8;
        melody[19] <= 4'd0;
        melody[20] <= 4'd8;
        melody[21] <= 4'd0;
        melody[22] <= 4'd8;
        melody[23] <= 4'd0;
        melody[24] <= 4'd0;
        melody[25] <= 4'd0;
        melody[26] <= 4'd0;
        melody[27] <= 4'd0;
        melody[28] <= 4'd0;
        melody[29] <= 4'd0;
        melody[30] <= 4'd0;
        melody[31] <= 4'd0;
        melody[32] <= 4'd8;
        melody[33] <= 4'd0;
        melody[34] <= 4'd8;
        melody[35] <= 4'd0;
        melody[36] <= 4'd8;
        melody[37] <= 4'd0;
        melody[38] <= 4'd8;
        melody[39] <= 4'd0;
        melody[40] <= 4'd0;
        melody[41] <= 4'd0;
        melody[42] <= 4'd0;
        melody[43] <= 4'd0;
        melody[44] <= 4'd0;
        melody[45] <= 4'd0;
        melody[46] <= 4'd0;
        melody[47] <= 4'd0;
        melody[48] <= 4'd8;
        melody[49] <= 4'd0;
        melody[50] <= 4'd8;
        melody[51] <= 4'd0;
        melody[52] <= 4'd8;
        melody[53] <= 4'd0;
        melody[54] <= 4'd8;
        melody[55] <= 4'd0;
        melody[56] <= 4'd0;
        melody[57] <= 4'd0;
        melody[58] <= 4'd0;
        melody[59] <= 4'd0;
        melody[60] <= 4'd0;
        melody[61] <= 4'd0;
        melody[62] <= 4'd0;
        melody[63] <= 4'd0;
    end

    always @(*) begin
        if (playing) note = melody[playing_index];
        else if (recording_mode) begin
            case (button)
                12'b1000_0000_0000: note = 4'd1; // C2
                12'b0100_0000_0000: note = 4'd2; // D2
                12'b0010_0000_0000: note = 4'd3; // E2
                12'b0001_0000_0000: note = 4'd4; // F2
                12'b0000_1000_0000: note = 4'd5; // G2
                12'b0000_0100_0000: note = 4'd6; // A2
                12'b0000_0010_0000: note = 4'd7; // B2
                12'b0000_0001_0000: note = 4'd8; // C3
                12'b0000_0000_1000: note = 4'd9; // D3
                default: note = 4'd0;
            endcase
        end
        else note = 4'd0;
    end

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            melody_index <= 0;
            playing_index <= 0;
            playing <= 0;
            count <= 0;
        end
        else begin
            if (recording_mode) begin
                if (button_t[0]) begin
                    melody_index <= 0;
                    playing_index <= 0;
                    playing <= 0;
                    count <= 0;
                end
                else if (button_t[1]) begin
                    playing_index <= 0;
                    playing <= 1;
                    count <= 0;
                end
                else if (|button_t[11:2]) begin
                    melody[melody_index + 0] <= note;
                    melody[melody_index + 1] <= note;
                    melody[melody_index + 2] <= note;
                    melody[melody_index + 3] <= note;
                    melody_index <= melody_index + 4;
                end

                if (melody_index == 0) recording_led <= 8'b1111_1111;
                else if (melody_index >= 56) recording_led <= 8'b1111_1110;
                else if (melody_index >= 48) recording_led <= 8'b1111_1100;
                else if (melody_index >= 40) recording_led <= 8'b1111_1000;
                else if (melody_index >= 32) recording_led <= 8'b1111_0000;
                else if (melody_index >= 24) recording_led <= 8'b1110_0000;
                else if (melody_index >= 16) recording_led <= 8'b1100_0000;
                else if (melody_index >= 8) recording_led <= 8'b1000_0000;
                else recording_led <= 8'b0000_0000;
            end

            if (playing) begin
                count <= count + 1;
                
                if (count >= 63) begin
                    count <= 0;
                    
                    if (melody_index == 0) begin
                        if (playing_index >= 63) begin
                            playing_index <= 0;
                            playing <= 0;
                        end
                        else playing_index <= playing_index + 1;
                    end
                    else begin
                        if (playing_index >= melody_index - 1) begin
                            playing_index <= 0;
                            playing <= 0;
                        end
                        else playing_index <= playing_index + 1;
                    end
                end
                
                if (timer_mode && !timer_started) begin
                    playing_index <= 0;
                    playing <= 0;
                end
            end

            if (alarm_t) begin
                playing_index <= 0;
                playing <= 1;
                count <= 0;
            end
        end
    end
endmodule

module piezo_player (
    input wire clock, reset,
    input wire [3:0] note,
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
    localparam D3 = 12'd1704;

    reg [11:0] count, limit;

    always @(*) begin
        if (!reset) limit = 12'd0;
        else begin
            case (note)
                4'd1: limit = C2;
                4'd2: limit = D2;
                4'd3: limit = E2;
                4'd4: limit = F2;
                4'd5: limit = G2;
                4'd6: limit = A2;
                4'd7: limit = B2;
                4'd8: limit = C3;
                4'd9: limit = D3;
                default: limit = 12'd0;
            endcase
        end
    end

    always @(posedge clock or negedge reset) begin
        if (!reset || !limit) begin
            count <= 0;
            PIEZO <= 0;
        end
        else if (count >= limit / 2) begin
            count <= 0;
            PIEZO <= ~PIEZO;
        end
        else count <= count + 1;
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
