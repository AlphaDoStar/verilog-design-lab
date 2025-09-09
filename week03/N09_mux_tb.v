module mux_tb;
    reg [31:0] i;
    reg [2:0] s;
    wire [3:0] o;
    reg [3:0] j;
    
    mux m1 (i, s, o);

    initial begin
        for (j = 0; j < 8; j = j + 1) begin
            i[(4 * j + 3):(4 * j)] = j;
        end

        for (j = 0; j < 8; j = j + 1) begin
            s = j; #10;
        end

        $stop;
    end
endmodule
