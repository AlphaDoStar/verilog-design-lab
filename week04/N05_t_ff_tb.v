module t_ff_tb;
    reg t, clk, rst;
    wire q;

    t_ff t1 (t, clk, rst, q);

    initial begin
        clk <= 0;
        rst <= 1;
        #10 rst <= 0;
        #10 rst <= 1;
        t <= 0;
        #10 t <= 1;
        #10 t <= 0;
        #10 t <= 1;
        #10 t <= 0;
        #10 t <= 1;
        #10 $stop;
    end

    always begin
        #5 clk <= ~clk;
    end
endmodule
