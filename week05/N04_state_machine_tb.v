module state_machine_tb;
    reg clk, rst;
    reg [2:0] x;
    wire [2:0] state;
    wire y;

    state_machine sm1 (clk, rst, x, state, y);

    initial begin
        clk <= 0;

        rst <= 0; #10
        rst <= 1;

        x <= 3'b100; #10
        x <= 3'b010; #10
        x <= 3'b100; #10
        x <= 3'b010; #10
        x <= 3'b001; #10

        rst <= 0; #10
        rst <= 1;

        x <= 3'b100; #10
        x <= 3'b010; #10
        x <= 3'b001; #10

        $stop;
    end

    always begin
        #1 clk <= ~clk;
    end
endmodule
