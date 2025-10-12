module up_counter_tb;
    reg clk, rst;
    reg x;
    wire [7:0] state;

    up_counter uc1 (clk, rst, x, state);

    initial begin
        clk <= 1;

        rst <= 0; #10
        rst <= 1;

        x <= 0; #10
        x <= 1; #10

        x <= 0; #10
        x <= 1; #10

        x <= 0; #10
        x <= 1; #10

        x <= 0; #10
        x <= 1; #10

        x <= 0; #10
        x <= 1; #10

        x <= 0; #10
        x <= 1; #10

        x <= 0; #10
        x <= 1; #10

        x <= 0; #10
        x <= 1; #10

        x <= 0; #10
        x <= 1; #10

        x <= 0; #10
        x <= 1; #10

        $stop;
    end

    always begin
        #1 clk <= ~clk;
    end
endmodule
