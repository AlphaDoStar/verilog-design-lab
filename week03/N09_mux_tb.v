module mux_tb;
    reg [31:0] i;
    reg [2:0] s;
    wire [3:0] o;
    reg [3:0] j;
    
    mux m1 (i, s, o);

    initial begin
        i = {4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7};

        for (j = 0; j < 8; j = j + 1) begin
            s = j; #10;
        end

        $stop;
    end
endmodule
