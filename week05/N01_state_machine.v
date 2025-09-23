module state_machine (
    input wire clk, rst, x,
    output reg [1:0] state,
    output reg y
);
    always @(posedge clk or negedge rst) begin
        if (!rst) state <= 2'b00;
        else begin
            case (state)
                2'b00: state <= x ? 2'b01 : 2'b00;
                2'b01: state <= x ? 2'b11 : 2'b00;
                2'b10: state <= x ? 2'b10 : 2'b00;
                2'b11: state <= x ? 2'b10 : 2'b00;
            endcase
        end
    end
    
    always @(posedge clk or negedge rst) begin
        if (!rst) y <= 0;
        else begin
            case (state)
                2'b00: y <= 1'b0;
                2'b01: y <= x ? 1'b0 : 1'b1;
                2'b10: y <= x ? 1'b0 : 1'b1; 
                2'b11: y <= x ? 1'b0 : 1'b1; 
            endcase
        end
    end
endmodule
