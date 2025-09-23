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

module state_machine (
    input wire clk, rst,
    input wire [2:0] x,
    output reg [2:0] state,
    output reg y
);
    parameter S0 = 3'b000;
    parameter S50 = 3'b001;
    parameter S100 = 3'b010;
    parameter S150 = 3'b011;
    parameter S200 = 3'b100;

    wire a, b, c;

    one_shot_trigger ost1 (clk, rst, x[2], a);
    one_shot_trigger ost2 (clk, rst, x[1], b);
    one_shot_trigger ost3 (clk, rst, x[0], c);

    always @(posedge clk or negedge rst) begin
        if (!rst) state <= S0;
        else begin
            case (state)
                S0: state <= a ? S50 : b ? S100 : S0;
                S50: state <= a ? S100 : b ? S150 : S50;
                S100: state <= a ? S150 : b ? S200 : S100;
                S150: state <= a | b ? S200 : S150;
                S200: state <= c ? S0 : S200;
            endcase
        end
    end
    
    always @(posedge clk or negedge rst) begin
        if (!rst) y <= 0;
        else begin
            case (state)
                S200: y <= c ? 1 : 0;
            endcase
        end
    end
endmodule
