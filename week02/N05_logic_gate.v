module half_adder (
    input wire x,
    input wire y,
    output wire c,
    output wire s
);
    assign c = x & y;
    assign s = x ^ y;
endmodule