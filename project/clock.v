module clock (
    input wire clock, reset,
    input wire [6:0] mode,
    input wire [11:0] button,
    output wire E, RS, RW,
    output wire [7:0] DATA, LED
);
    wire [11:0] button_t;

    reg [9:0] count;

    reg [3:0] country;
    reg [4:0] hour;
    reg [5:0] minute, second;
    reg mode_12_24;

    one_shot_trigger #(.WIDTH(12)) ost1 (clock, reset, button, button_t);
    lcd_display ld1 (clock, reset, country, hour, minute, second, mode_12_24, E, RS, RW, DATA);

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            count <= 0;
            country <= 4'h0;
            hour <= 0;
            minute <= 0;
            second <= 0;
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
    input wire [3:0] country,
    input wire [4:0] hour,
    input wire [5:0] minute, second,
    input wire mode_12_24,
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

    wire [15:0] am_pm = get_am_pm(mode_12_24, hour);

    wire [23:0] foreign_country_name = get_contry_name(country);
    wire [4:0] foreign_hour = get_foreign_hour(country, hour);
    wire [15:0] foreign_am_pm = get_am_pm(mode_12_24, foreign_hour);

    reg [6:0] count;
    reg [2:0] state;

    reg [3:0] prev_country;
    reg [5:0] prev_second;
    reg prev_mode;

    wire input_changed = (country != prev_country) || (second != prev_second) || (mode_12_24 != prev_mode);

    assign E = clock;

    always @(posedge clock or negedge reset) begin
        if (!reset) begin
            count <= 0;
            state <= DELAY;
            prev_country <= 0;
            prev_second <= 0;
            prev_mode <= 0;
        end
        else begin
            count <= count + 1;
            prev_country <= country;
            prev_second <= second;
            prev_mode <= mode_12_24;
            case (state)
                DELAY: begin
                    LED <= 8'b1000_0000;
                    if (count >= 70) begin
                        count <= 0;
                        state <= FUNCTION_SET;
                    end
                end
                FUNCTION_SET: begin
                    LED <= 8'b0100_0000;
                    if (count >= 30) begin
                        count <= 0;
                        state <= DISP_ONOFF;
                    end
                end
                DISP_ONOFF: begin
                    LED <= 8'b0010_0000;
                    if (count >= 30) begin
                        count <= 0;
                        state <= ENTRY_MODE;
                    end
                end
                ENTRY_MODE: begin
                    LED <= 8'b0001_0000;
                    if (count >= 30) begin
                        count <= 0;
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    LED <= 8'b0000_1000;
                    if (count >= 40) begin
                        count <= 0;
                        state <= DELAY_T;
                    end
                end
                DELAY_T: begin
                    count <= 0;
                    LED <= 8'b0000_0100;
                    if (input_changed) begin
                        state <= CURSOR_AT_HOME;
                    end
                end
                CURSOR_AT_HOME: begin
                    LED <= 8'b0000_0010;
                    if (count >= 5) begin
                        count <= 0;
                        state <= CLEAR_DISP;
                    end
                end
                CLEAR_DISP: begin
                    LED <= 8'b0000_0001;
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
                    case (count)
                        00: {RS, RW, DATA} <= 10'b00_1000_0000;
                        01: {RS, RW, DATA} <= {2'b00, 8'h4B}; // K
                        02: {RS, RW, DATA} <= {2'b00, 8'h4F}; // O
                        03: {RS, RW, DATA} <= {2'b00, 8'h52}; // R
                        04: {RS, RW, DATA} <= 10'b00_0010_0000;
                        05: {RS, RW, DATA} <= 10'b00_0011_0000 + (hour / 10);
                        06: {RS, RW, DATA} <= 10'b00_0011_0000 + (hour % 10);
                        07: {RS, RW, DATA} <= {2'b00, 8'h3A}; // :
                        08: {RS, RW, DATA} <= 10'b00_0011_0000 + (minute / 10);
                        09: {RS, RW, DATA} <= 10'b00_0011_0000 + (minute % 10);
                        10: {RS, RW, DATA} <= {2'b00, 8'h3A}; // :
                        11: {RS, RW, DATA} <= 10'b00_0011_0000 + (second / 10);
                        12: {RS, RW, DATA} <= 10'b00_0011_0000 + (second % 10);
                        13: {RS, RW, DATA} <= 10'b00_0010_0000;
                        14: {RS, RW, DATA} <= {2'b00, am_pm[15:8]};
                        15: {RS, RW, DATA} <= {2'b00, am_pm[7:0]};

                        16: {RS, RW, DATA} <= 10'b00_1100_0000;
                        17: {RS, RW, DATA} <= {2'b00, foreign_country_name[23:16]};
                        18: {RS, RW, DATA} <= {2'b00, foreign_country_name[15:8]};
                        19: {RS, RW, DATA} <= {2'b00, foreign_country_name[7:0]};
                        20: {RS, RW, DATA} <= 10'b00_0010_0000;
                        21: {RS, RW, DATA} <= 10'b00_0011_0000 + (foreign_hour / 10);
                        22: {RS, RW, DATA} <= 10'b00_0011_0000 + (foreign_hour % 10);
                        23: {RS, RW, DATA} <= {2'b00, 8'h3A}; // :
                        24: {RS, RW, DATA} <= 10'b00_0011_0000 + (minute / 10);
                        25: {RS, RW, DATA} <= 10'b00_0011_0000 + (minute % 10);
                        26: {RS, RW, DATA} <= {2'b00, 8'h3A}; // :
                        27: {RS, RW, DATA} <= 10'b00_0011_0000 + (second / 10);
                        28: {RS, RW, DATA} <= 10'b00_0011_0000 + (second % 10);
                        29: {RS, RW, DATA} <= 10'b00_0010_0000;
                        30: {RS, RW, DATA} <= {2'b00, foreign_am_pm[15:8]};
                        31: {RS, RW, DATA} <= {2'b00, foreign_am_pm[7:0]};

                        default: {RS, RW, DATA} <= 10'b11_0000_0000;
                    endcase
                end
                DELAY_T: {RS, RW, DATA} <= 10'b11_0000_0000;
                CURSOR_AT_HOME: {RS, RW, DATA} <= 10'b00_0000_0010;
                CLEAR_DISP: {RS, RW, DATA} <= 10'b00_0000_0001;
            endcase
        end
    end
endmodule
