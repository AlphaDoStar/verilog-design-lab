module decoder_tb;
    reg x, y, z;
    wire [3:0] d;
    reg [7:0] i;
    
    decoder d1 (x, y, z, d);

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            {x, y, z} = i; #10;
        end
        $stop;
    end
endmodule
