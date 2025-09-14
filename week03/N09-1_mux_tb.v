module mux_tb;
    reg [7:0] i;
    reg [1:0] s;
    wire [1:0] o;
    
    mux m1 (i, s, o);

    initial begin
        i[1:0] = 2'b11;
        i[3:2] = 2'b10;
        i[5:4] = 2'b01;
        i[7:6] = 2'b00;

        s = 2'b00; #10;
        s = 2'b01; #10;
        s = 2'b10; #10;
        s = 2'b11; #10;

        $stop;
    end
endmodule
