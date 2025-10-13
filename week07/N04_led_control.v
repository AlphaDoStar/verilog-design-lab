module led_control (
    input wire clk, rst,
    input wire [7:0] bin,
    output wire [7:0] sel, value,
    output reg led
);
    wire [7:0] cnt;

    counter c1 (clk, rst, cnt);
    display d1 (clk, rst, bin, sel, value);

    always @(posedge clk or posedge rst) begin
        if (rst) led <= 0;
        else begin
            if (cnt <= bin) led <= 1;
            else led <= 0;
        end
    end
endmodule

module counter (
    input wire clk, rst,
    output reg [7:0] cnt
);
    always @(posedge clk or posedge rst) begin
        if (rst) cnt <= 8'd0;
        else cnt <= cnt + 1;
    end
endmodule

module display (
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

    always @(posedge clk or posedge rst) begin
        if (rst) sel <= 8'b11111110;
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

module bin_to_bcd (
    input wire clk, rst,
    input wire [7:0] bin,
    output reg [11:0] bcd
);
    reg [11:0] state;
    reg [2:0] i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
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

    always @(posedge rst or posedge clk) begin
        if (rst) bcd <= 12'b0000_0000_0000;
        else if (i == 0) bcd <= state;
    end
endmodule
