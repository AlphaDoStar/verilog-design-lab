module logic_gate (x, y, a, b, c, d, e);
    input x, y;
    output a, b, c, d, e;
    wire a, b, c, d, e;
    
    assign a = x & y;
    assign b = x | y;
    assign c = x ^ y;
    assign d = ~(x | y);
    assign e = ~(x & y);
endmodule
