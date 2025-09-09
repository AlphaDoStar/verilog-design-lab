module decoder_tb;
    reg [3:0] d;
    wire x, y, z;
    
    priority_encoder e1 (d, x, y, z);

    initial begin
        d = 4'b0000; #10;
        d = 4'b1000; #10;
        d = 4'b1011; #10;
        d = 4'b0101; #10;
        d = 4'b0001; #10;
        $stop;
    end
endmodule
