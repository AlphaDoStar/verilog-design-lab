module up_counter_tb;
    reg clk, rst, btn;
    wire [7:0] sel, value;

    up_counter uc1 (
        .clk(clk),
        .rst(rst),
        .btn(btn),
        .sel(sel),
        .value(value)
    );

    initial clk = 1;
    always #1 clk = ~clk;

    initial begin
        rst = 0;
        btn = 0; #50;
        
        rst = 1;
        
        repeat(16) begin
            btn = 1; #25;
            btn = 0; #25;
        end
        
        $stop;
    end
endmodule
