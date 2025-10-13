`timescale 1ns / 1ps

module led_control_tb;
    reg clk, rst;
    reg [7:0] btn;
    wire [3:0] R, G, B;

    led_control lc1 (clk, rst, btn, R, G, B);

    initial clk = 1;
    always #0.5 clk = ~clk;

    initial begin
        rst = 1;
        btn = 8'd0;

        #1e+3 rst = 0;

        #1e+3 btn = 8'b00000001;
        #1e+3 btn = 8'b00000010;
        #1e+3 btn = 8'b00000100;

        #1e+3 $stop;
    end
endmodule
