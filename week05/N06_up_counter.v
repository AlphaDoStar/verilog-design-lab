module one_shot_trigger(
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
    output reg [1:0] state
);
    wire a;

    one_shot_trigger ost1(clk, rst, x, a);

    always @(posedge clk or negedge rst) begin
        if (!rst) state <= 2'b00;
        else begin
            case (state)
                2'b00: state <= a ? 2'b01 : 2'b00;
                2'b01: state <= a ? 2'b10 : 2'b01;
                2'b10: state <= a ? 2'b11 : 2'b10;
                2'b11: state <= a ? 2'b00 : 2'b11;
            endcase
        end
    end
endmodule
