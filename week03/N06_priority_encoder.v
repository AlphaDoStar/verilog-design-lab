module priority_encoder (
    input wire [3:0] d,
    output reg x, y, v
);
    always @(d) begin
        casex (d)
            4'b1xxx: {x, y, v} = 3'b111;
            4'b01xx: {x, y, v} = 3'b101;
            4'b001x: {x, y, v} = 3'b011;
            4'b0001: {x, y, v} = 3'b001;
            default: {x, y, v} = 3'b000;
        endcase
    end
endmodule
