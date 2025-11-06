module dac (
    input wire clk, rst, sel,
    input wire [5:0] btn,
    output reg AB, CS, WR, LDAC,
    output reg [7:0] D, LED,
    output wire [7:0] seg_sel, seg_value,
    output wire E, RS, RW,
    output wire [7:0] DATA
);
    localparam DELAY = 2'b00;
    localparam SET_WRN = 2'b01;
    localparam UP_DATA = 2'b10;

    reg [7:0] bin, cnt;
    reg [1:0] state;

    wire [7:0] btn_t;

    one_shot_trigger #(.WIDTH(6)) ost1 (clk, rst, btn, btn_t);
    segment_display sd1 (clk, rst, bin, seg_sel, seg_value);
    lcd_display ld1 (clk, rst, bin, E, RS, RW, DATA);
    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cnt <= 0;
            state <= DELAY;
        end
        else begin
            cnt <= cnt + 1;
            case (state)
                DELAY: begin
                    if (cnt >= 200) begin
                        cnt <= 0;
                        state <= SET_WRN;
                    end
                end
                SET_WRN: begin
                    if (cnt >= 50) begin
                        cnt <= 0;
                        state <= UP_DATA;
                    end
                end
                UP_DATA: begin
                    if (cnt >= 30) begin
                        cnt <= 0;
                        state <= DELAY;
                    end
                end
            endcase
        end
    end

    always @(posedge clk) begin
        AB <= sel;
        CS <= 0;
        LDAC <= 0;
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            bin <= 8'b0000_0000;
            LED <= 8'b0000_0000;
        end
        else begin
            casez (btn_t)
                6'b1?????: bin <= bin - 8'b0000_0001;
                6'b01????: bin <= bin + 8'b0000_0001;
                6'b001???: bin <= bin - 8'b0000_0010;
                6'b0001??: bin <= bin + 8'b0000_0010;
                6'b00001?: bin <= bin - 8'b0000_1000;
                6'b000001: bin <= bin + 8'b0000_1000;
            endcase
            LED <= bin;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) WR <= 1;
        else begin
            case (state)
                DELAY: WR <= 1;
                SET_WRN: WR <= 0;
                UP_DATA: D <= bin;
            endcase
        end
    end
endmodule

module one_shot_trigger #(parameter WIDTH = 1)(
    input wire clk, rst,
    input wire [WIDTH-1:0] i,
    output reg [WIDTH-1:0] o
);
    reg [WIDTH-1:0] r;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            r <= {WIDTH{1'b0}};
            o <= {WIDTH{1'b0}};
        end
        else begin
            r <= i;
            o <= i & ~r;
        end
    end
endmodule

module segment_display (
    input wire clk, rst,
    input wire [7:0] bin,
    output reg [7:0] sel, value
);
    localparam S0 = 8'b11111100;
    localparam S1 = 8'b01100000;
    localparam S2 = 8'b11011010;
    localparam S3 = 8'b11110010;
    localparam S4 = 8'b01100110;
    localparam S5 = 8'b10110110;
    localparam S6 = 8'b10111110;
    localparam S7 = 8'b11100100;
    localparam S8 = 8'b11111110;
    localparam S9 = 8'b11110110;

    wire [11:0] bcd;
    reg [3:0] state;

    bin_to_bcd btb1 (clk, rst, bin, bcd);

    always @(posedge clk or negedge rst) begin
        if (!rst) sel <= 8'b11111110;
        else sel <= {sel[6:0], sel[7]};
    end

    always @(*) begin
        case (sel)
            8'b11111110: state = bcd[3:0];
            8'b11111101: state = bcd[7:4];
            8'b11111011: state = bcd[11:8];
            default: state = 4'd0;
        endcase
    end

    always @(*) begin
        case (state)
            4'd0: value = S0;
            4'd1: value = S1;
            4'd2: value = S2;
            4'd3: value = S3;
            4'd4: value = S4;
            4'd5: value = S5;
            4'd6: value = S6;
            4'd7: value = S7;
            4'd8: value = S8;
            4'd9: value = S9;
            default: value = 8'd0;
        endcase
    end
endmodule

module lcd_display (
    input wire clk, rst,
    input wire [7:0] bin,
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

    wire [11:0] bcd;

    integer cnt;
    
    reg [2:0] state;
    reg [11:0] bcd_prev;

    bin_to_bcd b1 (clk, rst, bin, bcd);

    assign E = clk;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cnt <= 0;
            state <= DELAY;
        end
        else begin
            cnt <= cnt + 1;
            bcd_prev <= bcd;
            case (state)
                DELAY: begin
                    if (cnt >= 70) begin
                        cnt <= 0;
                        state <= FUNCTION_SET;
                    end
                end
                FUNCTION_SET: begin
                    if (cnt >= 30) begin
                        cnt <= 0;
                        state <= DISP_ONOFF;
                    end
                end
                DISP_ONOFF: begin
                    if (cnt >= 30) begin
                        cnt <= 0;
                        state <= ENTRY_MODE;
                    end
                end
                ENTRY_MODE: begin
                    if (cnt >= 30) begin
                        cnt <= 0;
                        state <= WRITE;
                    end
                end
                WRITE: begin
                    if (cnt >= 5) begin
                        cnt <= 0;
                        state <= DELAY_T;
                    end
                end
                DELAY_T: begin
                    cnt <= 0;
                    if (bcd != bcd_prev) begin
                        state <= CURSOR_AT_HOME;
                    end
                end
                CURSOR_AT_HOME: begin
                    if (cnt >= 5) begin
                        cnt <= 0;
                        state <= CLEAR_DISP;
                    end
                end
                CLEAR_DISP: begin
                    if (cnt >= 5) begin
                        cnt <= 0;
                        state <= WRITE;
                    end
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) {RS, RW, DATA} <= 10'b00_0011_0000;
        else begin
            case (state)
                DELAY: {RS, RW, DATA} <= 10'b11_0000_0000;
                FUNCTION_SET: {RS, RW, DATA} <= 10'b00_0011_0000;
                DISP_ONOFF: {RS, RW, DATA} <= 10'b00_0000_1100;
                ENTRY_MODE: {RS, RW, DATA} <= 10'b00_0000_0110;
                WRITE: begin
                    case (cnt)
                        0: {RS, RW, DATA} <= 10'b00_1000_0000;
                        1: {RS, RW, DATA} <= 10'b10_0011_0000 + bcd[11:8];
                        2: {RS, RW, DATA} <= 10'b10_0011_0000 + bcd[7:4];
                        3: {RS, RW, DATA} <= 10'b10_0011_0000 + bcd[3:0];
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

module bin_to_bcd (
    input wire clk, rst,
    input wire [7:0] bin,
    output reg [11:0] bcd
);
    reg [11:0] state;
    reg [2:0] i;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= 12'b0000_0000_0000;
            i <= 0;
        end
        else begin
            if (i == 0) begin
                state[11:1] <= 11'b0000_0000_000;
                state[0] <= bin[7];
            end
            else begin
                state[11:9] <= (state[11:8] >= 3'd5) ? state[11:8] + 2'd3 : state[11:8];
                state[8:5] <= (state[7:4] >= 3'd5) ? state[7:4] + 2'd3 : state[7:4];
                state[4:1] <= (state[3:0] >= 3'd5) ? state[3:0] + 2'd3 : state[3:0];
                state[0] <= bin[7 - i];
            end
            i <= i + 1;
        end

    end

    always @(posedge clk or negedge rst) begin
        if (!rst) bcd <= 12'b0000_0000_0000;
        else if (i == 0) bcd <= state;
    end
endmodule
