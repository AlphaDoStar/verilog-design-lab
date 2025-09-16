module t_ff_os (
    input wire t, clk, rst,
    output reg q
);
    reg t_reg;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            q <= 0;
            t_reg <= 0;
        end
        else begin
            t_reg <= t;
            if (t & ~t_reg) q <= ~q;
        end
    end
endmodule
