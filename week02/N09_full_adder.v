module half_adder (
    input wire x,
    input wire y,
    output wire c,
    output wire s
);
    assign c = x & y;
    assign s = x ^ y;
endmodule

module full_adder (
    input wire x, y, cin,
    output wire cout, sum
);
    wire c1, c2, s1;
    
    half_adder ha1 (.x(x), .y(y), .c(c1), .s(s1));
    half_adder ha2 (.x(s1), .y(cin), .c(c2), .s(sum));
    
    assign cout = c1 | c2;
endmodule
