module logic_gate_tb;
    reg x, y;
    wire a, b, c, d, e;
    
    logic_gate lg1 (x, y, a, b, c, d, e);
    
    initial begin
        x = 0; y = 0; #10
        x = 0; y = 1; #10
        x = 1; y = 0; #10
        x = 1; y = 1; #10
        $stop;
    end
endmodule
