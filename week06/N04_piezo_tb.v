`timescale 1us / 1ns

module piezo_tb;
    reg clk, rst;
    reg [7:0] btn;
    wire piezo;

    piezo p1 (clk, rst, btn, piezo);

    initial clk = 1;
    always #0.5 clk = ~clk;

    initial begin
        rst = 1;
        btn = 8'b00000000;

        #1e+6 rst = 0;
        #1e+6 rst = 1;

        #1e+6 btn = 8'b00000010;
        #1e+6 btn = 8'b00100000;

        #1e+6 $stop;
    end
endmodule
