module t_ff (
    input wire t, clk, rst,
    output reg q
);
    always @(posedge clk or negedge rst) begin
        if (!rst) q <= 0;
        else if (t) q <= ~q;
    end
endmodule
