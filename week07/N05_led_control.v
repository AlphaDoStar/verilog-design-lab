module led_control (
    input wire clk, rst,
    input wire [7:0] btn,
    output reg [3:0] R, G, B
);
    localparam RED = {8'd255, 8'd0, 8'd0};
    localparam ORANGE = {8'd255, 8'd102, 8'd0};
    localparam YELLOW = {8'd255, 8'd255, 8'd0};
    localparam GREEN = {8'd0, 8'd255, 8'd0};
    localparam BLUE = {8'd0, 8'd0, 8'd255};
    localparam INDIGO = {8'd0, 8'd0, 8'd128};
    localparam PURPLE = {8'd128, 8'd0, 8'd128};
    localparam WHITE = {8'd255, 8'd255, 8'd255};

    wire [7:0] cnt;
    reg [23:0] state;

    counter c1 (clk, rst, cnt);

    always @(posedge clk or posedge rst) begin
        if (rst) state <= 24'd0;
        else begin
            case (btn)
                8'b00000001: state <= RED;
                8'b00000010: state <= ORANGE;
                8'b00000100: state <= YELLOW;
                8'b00001000: state <= GREEN;
                8'b00010000: state <= BLUE;
                8'b00100000: state <= INDIGO;
                8'b01000000: state <= PURPLE;
                8'b10000000: state <= WHITE;
                // default: state <= 24'd0;
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            R <= 4'b0000;
            G <= 4'b0000;
            B <= 4'b0000;
        end
        else begin
            if (cnt <= state[23:16]) R <= 4'b1111;
            else R <= 4'b0000;

            if (cnt <= state[15:8]) G <= 4'b1111;
            else G <= 4'b0000;

            if (cnt <= state[7:0]) B <= 4'b1111;
            else B <= 4'b0000;
        end
    end
endmodule

module counter (
    input wire clk, rst,
    output reg [7:0] cnt
);
    always @(posedge clk or posedge rst) begin
        if (rst) cnt <= 8'd0;
        else cnt <= cnt + 1;
    end
endmodule
