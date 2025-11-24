`timescale 1ns / 1ps

module tb_clock;
    reg clock, reset;
    reg [6:0] mode;
    reg [11:0] button;
    
    wire E, RS, RW;
    wire [7:0] DATA;

    clock uut (
        .clock(clock),
        .reset(reset),
        .mode(mode),
        .button(button),
        .E(E),
        .RS(RS),
        .RW(RW),
        .DATA(DATA)
    );

    initial begin
        clock = 0;
        reset = 0;
        mode = 7'b0000000;
        button = 12'b0000_0000_0000;
        
        #100 reset = 1;
        
        #1000000;
        
        $finish;
    end

    always #5 clock = ~clock;

    initial begin
        $dumpfile("clock.vcd");
        $dumpvars(0, tb_clock);
    end
endmodule
