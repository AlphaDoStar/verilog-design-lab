module half_adder (
    input wire x,
    input wire y,
    output reg c,
    output reg s
);
    always @(*) begin
        case ({x, y})
            2'b00: {c, s} = 2'b00;
            2'b01: {c, s} = 2'b01;
            2'b10: {c, s} = 2'b01;
            2'b11: {c, s} = 2'b10;
        endcase
    end
endmodule