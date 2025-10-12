module piezo (
    input wire clk, rst,
    input wire [7:0] btn,
    output reg piezo
);
    localparam C2 = 12'd3830;
    localparam D2 = 12'd3400;
    localparam E2 = 12'd3038;
    localparam F2 = 12'd2864;
    localparam G2 = 12'd2550;
    localparam A2 = 12'd2272;
    localparam B2 = 12'd2028;
    localparam C3 = 12'd1912;

    reg [11:0] cnt, lim;

    always @(*) begin
        if (!rst) lim = 12'd0;
        else begin
            casez (btn)
                8'b00000001: lim = C2;
                8'b0000001?: lim = D2;
                8'b000001??: lim = E2;
                8'b00001???: lim = F2;
                8'b0001????: lim = G2;
                8'b001?????: lim = A2;
                8'b01??????: lim = B2;
                8'b1???????: lim = C3;
                default: lim = 12'd0;
            endcase
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst || !lim) begin
            piezo <= 0;
            cnt <= 0;
        end
        else if (cnt >= lim / 2) begin
            piezo <= ~piezo;
            cnt <= 0;
        end
        else cnt <= cnt + 1;
    end
endmodule
