`timescale 1us / 1ns

module led_control_tb;
    reg clk, rst;
    reg [7:0] bin;
    wire [7:0] sel, value;
    wire led;

    led_control lc1 (clk, rst, bin, sel, value, led);

    initial clk = 1;
    always #0.5 clk = ~clk;

    initial begin
        rst = 0;
        bin = 8'd0;

        #1e+3 rst = 1;
        #1e+3 rst = 0;

        #1e+3 bin = 8'd64;
        #1e+3 bin = 8'd128;
        #1e+3 bin = 8'd192;
        #1e+3 bin = 8'd255;

        #1e+3 $stop;
    end
endmodule
