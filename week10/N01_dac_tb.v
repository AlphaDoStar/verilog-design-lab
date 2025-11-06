`timescale 1ns / 1ps

module dac_tb;
    reg clk, rst, sel;
    reg [5:0] btn;
    wire AB, CS, WR, LDAC;
    wire [7:0] D, LED;
    wire [7:0] seg_sel, seg_value;
    wire E, RS, RW;
    wire [7:0] DATA;

    dac d1 (clk, rst, sel, btn,
        AB, CS, WR, LDAC, D, LED,
        seg_sel, seg_value,
        E, RS, RW, DATA);

    initial clk = 1;
    always #0.5 clk = ~clk;

    initial begin
        sel = 0;
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
