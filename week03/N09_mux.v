module mux (
    input wire [31:0] i,
    input wire [2:0] s,
    output reg [3:0] o
);
    always @(*) begin
        case (s)
            0: o = i[3:0];
            1: o = i[7:4];
            2: o = i[11:8];
            3: o = i[15:12];
            4: o = i[19:16];
            5: o = i[23:20];
            6: o = i[27:24];
            7: o = i[31:28];
        endcase
    end
endmodule
