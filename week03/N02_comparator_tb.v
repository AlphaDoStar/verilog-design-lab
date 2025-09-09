module comparator_tb;
    reg [3:0] a, b;
    wire x, y, z;
    
    comparator c1 (a, b, x, y, z);

    initial begin
        {a, b} = 8'b00111000; #10
        {a, b} = 8'b01110001; #10
        {a, b} = 8'b10011001; #10
        {a, b} = 8'b10111111; #10
        $stop;
    end
endmodule
