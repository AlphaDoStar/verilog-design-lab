module mux (
    input wire [7:0] i,
    input wire [1:0] s,
    output reg [1:0] o
);
    always @(*) begin
        case (s)
            0: o = i[1:0];
            1: o = i[3:2];
            2: o = i[5:4];
            3: o = i[7:6];
        endcase
    end
endmodule
