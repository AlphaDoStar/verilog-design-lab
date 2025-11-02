`timescale 1ns / 1ps

module cursor_tb;
    reg clk, rst;
    reg [9:0] num;
    reg [1:0] ctrl;
    wire E, RS, RW;
    wire [7:0] DATA, LED;

    cursor c1 (clk, rst, num, ctrl, E, RS, RW, DATA, LED);

    initial clk = 1;
    always #0.5 clk = ~clk;

    initial begin
        {num, ctrl} = 12'b0000_0000_0000;
    
        rst = 0; #10
        rst = 1; #390

        {num, ctrl} = 12'b1000_0000_0000; #1e+2
        {num, ctrl} = 12'b0100_0000_0000; #1e+2
        {num, ctrl} = 12'b0000_0000_0010; #1e+2
        {num, ctrl} = 12'b0000_0000_0001; #1e+2

        $stop;
    end
endmodule
