module jk_ff_tb;
    reg j, k, clk;
    wire q;

    jk_ff jk1 (j, k, clk, q);

    initial begin
        clk <= 0;
        {j, k} <= 2'b00;
        #10 {j, k} <= 2'b01;
        #10 {j, k} <= 2'b00;
        #10 {j, k} <= 2'b10;
        #10 {j, k} <= 2'b00;
        #10 {j, k} <= 2'b11;
        #10 {j, k} <= 2'b00;
        #10 $stop;
    end

    always begin
        #5 clk <= ~clk;
    end
endmodule
