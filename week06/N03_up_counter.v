module one_shot_trigger (
    input wire clk, rst, i,
    output reg o
);
    reg r;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            r <= 0;
            o <= 0;
        end
        else begin
            r <= i;
            o <= i & ~r;
        end
    end
endmodule

module bin_to_bcd (
    input wire clk, rst,
    input wire [3:0] bin,
    output reg [7:0] bcd
);
    always @(posedge clk or negedge rst) begin
        if (!rst) bcd <= {4'd0, 4'd0};
        else begin
            case (bin)
                0: bcd <= {4'd0, 4'd0};
                1: bcd <= {4'd0, 4'd1};
                2: bcd <= {4'd0, 4'd2};
                3: bcd <= {4'd0, 4'd3};
                4: bcd <= {4'd0, 4'd4};
                5: bcd <= {4'd0, 4'd5};
                6: bcd <= {4'd0, 4'd6};
                7: bcd <= {4'd0, 4'd7};
                8: bcd <= {4'd0, 4'd8};
                9: bcd <= {4'd0, 4'd9};
                10: bcd <= {4'd1, 4'd0};
                11: bcd <= {4'd1, 4'd1};
                12: bcd <= {4'd1, 4'd2};
                13: bcd <= {4'd1, 4'd3};
                14: bcd <= {4'd1, 4'd4};
                15: bcd <= {4'd1, 4'd5};
                default: bcd <= {4'd0, 4'd0};
            endcase
        end
    end
endmodule

module up_counter (
    input wire clk, rst, btn,
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

    wire trig;

    reg [3:0] bin, state;
    wire [7:0] bcd;

    one_shot_trigger ost1 (clk, rst, btn, trig);
    bin_to_bcd btb1 (clk, rst, bin, bcd);

    // move display
    always @(posedge clk or negedge rst) begin
        if (!rst) sel <= 8'b11111110;
        else sel <= {sel[6:0], sel[7]};
    end

    // count up
    always @(posedge clk or negedge rst) begin
        if (!rst) bin <= 4'd0;
        else if (trig) bin <= bin + 1;
    end

    always @(*) begin
        case (sel)
            8'b11111110: state = bcd[3:0];
            8'b11111101: state = bcd[7:4];
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
            default: value = S0;
        endcase
    end
endmodule
