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

module up_down_counter (
    input wire clk, rst,
    input wire x,
    output reg [2:0] state
);
    wire a;
    reg d;  // up: 0, down: 1

    one_shot_trigger ost1(clk, rst, x, a);

    always @(posedge clk or negedge rst) begin
        if (!rst) state <= 3'b000;
        else if (a) begin
            case (state)
                3'b000: state <= 3'b001;
                3'b001: state <= d ? 3'b000 : 3'b010;
                3'b010: state <= d ? 3'b001 : 3'b011;
                3'b011: state <= d ? 3'b010 : 3'b100;
                3'b100: state <= d ? 3'b011 : 3'b101;
                3'b101: state <= d ? 3'b100 : 3'b110;
                3'b110: state <= d ? 3'b101 : 3'b111;
                3'b111: state <= 3'b110;
            endcase
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) d <= 0;
        else if (a) begin
            case (state)
                3'b000: d <= 0;
                3'b111: d <= 1;
            endcase
        end
    end
endmodule
