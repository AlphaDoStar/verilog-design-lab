module comparator (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire x, y, z
);
    assign x = a > b;
    assign y = a == b;
    assign z = a < b;
endmodule
