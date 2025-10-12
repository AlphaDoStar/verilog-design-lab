module bin_to_bcd (
    input wire clk, rst,
    input wire [3:0] bin,
    output reg [7:0] bcd
);
    always @(posedge clk or negedge rst) begin
        if (!rst) bcd <= {4'd0, 4'd0};
        else begin
            case (bin)
                0: bcd <= {4'd0, 4'd0};
                1: bcd <= {4'd0, 4'd1};
                2: bcd <= {4'd0, 4'd2};
                3: bcd <= {4'd0, 4'd3};
                4: bcd <= {4'd0, 4'd4};
                5: bcd <= {4'd0, 4'd5};
                6: bcd <= {4'd0, 4'd6};
                7: bcd <= {4'd0, 4'd7};
                8: bcd <= {4'd0, 4'd8};
                9: bcd <= {4'd0, 4'd9};
                10: bcd <= {4'd1, 4'd0};
                11: bcd <= {4'd1, 4'd1};
                12: bcd <= {4'd1, 4'd2};
                13: bcd <= {4'd1, 4'd3};
                14: bcd <= {4'd1, 4'd4};
                15: bcd <= {4'd1, 4'd5};
                default: bcd <= {4'd0, 4'd0};
            endcase
        end
    end
endmodule
