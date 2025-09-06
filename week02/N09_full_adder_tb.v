module full_adder_tb;
    reg x, y, cin;
    wire cout, sum;
    reg [3:0] i;
    
    full_adder fa1 (x, y, cin, cout, sum);
    
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            {x, y, cin} = i; #10;
        end
        $stop;
    end
endmodule
