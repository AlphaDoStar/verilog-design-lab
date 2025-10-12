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

module up_counter (
    input wire clk, rst,
    input wire x,
    output reg [7:0] state
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

    wire a;

    one_shot_trigger ost1 (clk, rst, x, a);

    always @(posedge clk or negedge rst) begin
        if (!rst) state <= S0;
        else begin
            case (state)
                S0: state <= a ? S1 : S0;
                S1: state <= a ? S2 : S1;
                S2: state <= a ? S3 : S2;
                S3: state <= a ? S4 : S3;
                S4: state <= a ? S5 : S4;
                S5: state <= a ? S6 : S5;
                S6: state <= a ? S7 : S6;
                S7: state <= a ? S8 : S7;
                S8: state <= a ? S9 : S8;
                S9: state <= a ? S0 : S9;
                default: state <= S0;
            endcase
        end
    end
endmodule
