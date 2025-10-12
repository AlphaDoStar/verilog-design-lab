module bin_to_bcd_tb;
    reg clk, rst;
    reg [3:0] bin;
    wire [8:0] bcd;

    bin_to_bcd btb1 (clk, rst, bin, bcd);

    initial begin
        clk <= 1;

        rst <= 0; #10
        rst <= 1;

        bin <= 4'd0; #10
        bin <= 4'd1; #10
        bin <= 4'd2; #10
        bin <= 4'd3; #10
        bin <= 4'd4; #10
        bin <= 4'd5; #10
        bin <= 4'd6; #10
        bin <= 4'd7; #10
        bin <= 4'd8; #10
        bin <= 4'd9; #10
        bin <= 4'd10; #10
        bin <= 4'd11; #10
        bin <= 4'd12; #10
        bin <= 4'd13; #10
        bin <= 4'd14; #10
        bin <= 4'd15; #10

        $stop;
    end

    always begin
        #5 clk <= ~clk;
    end
endmodule
