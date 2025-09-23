module state_machine_tb;
    reg clk, rst, x;
    wire [1:0] state;
    wire y;

    state_machine sm1 (clk, rst, x, state, y);

    initial begin
        clk <= 0;

        // 2'b00, 1
        rst <= 0; #10
        rst <= 1;
        x <= 1;   #10

        // 2'b01, 0
        rst <= 0; #10
        rst <= 1;
        x <= 1;   #10
        x <= 0;   #10

        // 2'b01, 1
        rst <= 0; #10
        rst <= 1;
        x <= 1;   #10
        x <= 1;   #10

        // 2'b10, 0
        rst <= 0; #10
        rst <= 1;
        x <= 1;   #10
        x <= 1;   #10
        x <= 1;   #10
        x <= 0;   #10

        // 2'b10, 1
        rst <= 0; #10
        rst <= 1;
        x <= 1;   #10
        x <= 1;   #10
        x <= 1;   #10
        x <= 1;   #10

        // 2'b11, 0
        rst <= 0; #10
        rst <= 1;
        x <= 1;   #10
        x <= 1;   #10
        x <= 0;   #10

        $stop;
    end

    always begin
        #5 clk <= ~clk;
    end
endmodule
