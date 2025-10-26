`timescale 1ns / 1ps

module display_name_tb;
    reg clk, rst;
    wire E, RS, RW;
    wire [7:0] DATA, LED;

    display_name dn1 (clk, rst, E, RS, RW, DATA, LED);

    initial clk = 1;
    always #0.5 clk = ~clk;

    initial begin
        rst = 0; #1
        rst = 1; #1e+3
        $stop;
    end
endmodule
