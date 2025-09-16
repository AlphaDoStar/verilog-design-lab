module d_ff_tb;
    reg d, clk;
    wire q;

    d_ff d1 (d, clk, q);

    initial begin
        clk <= 0;
        d <= 0;
        #10 d <= 1;
        #10 d <= 0;
        #10 d <= 1;
        #10 d <= 0;
        #10 d <= 1;
        #10 $stop;
    end

    always begin
        #5 clk <= ~clk;
    end
endmodule
