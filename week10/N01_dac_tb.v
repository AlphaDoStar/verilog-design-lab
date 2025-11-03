`timescale 1ns / 1ps

module cursor_tb;
    reg clk, rst;
    reg [5:0] btn;
    wire AB, CS, WR, LDAC;
    wire [7:0] D, LED;

    dac d1 (clk, rst, num, ctrl, E, RS, RW, DATA, LED);

    initial clk = 1;
    always #0.5 clk = ~clk;

    initial begin
        btn = 6'b000000;
    
        rst = 0; #1e+2
        rst = 1; #4e+2

        btn = 6'b100000; #5e+2
        btn = 6'b010000; #5e+2
        btn = 6'b001000; #5e+2
        btn = 6'b000100; #5e+2
        btn = 6'b000010; #5e+2
        btn = 6'b000001; #5e+2

        $stop;
    end
endmodule
