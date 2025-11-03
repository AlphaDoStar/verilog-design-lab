module dac (
    input wire clk, rst, sel,
    input wire [5:0] btn,
    output reg AB, CS, WR, LDAC,
    output reg [7:0] D, LED
);
    localparam DELAY = 2'b00;
    localparam SET_WRN = 2'b01;
    localparam UP_DATA = 2'b10;

    reg [7:0] d, cnt;
    reg [1:0] state;

    wire btn_t;

    one_shot_trigger #(.WIDTH(6)) ost1 (clk, rst, btn, btn_t);

    always @(posedge clk or negedge rst) begin
        if (!rst) state <= DELAY;
        else begin
            cnt <= cnt + 1;
            case (state)
                DELAY: begin
                    if (cnt >= 200) begin
                        cnt <= 0;
                        state <= SET_WRN;
                    end
                end
                SET_WRN: begin
                    if (cnt >= 50) begin
                        cnt <= 0;
                        state <= UP_DATA;
                    end
                end
                UP_DATA: begin
                    if (cnt >= 30) begin
                        cnt <= 0;
                        state <= DELAY;
                    end
                end
                default: 
            endcase
        end
    end

    always @(posedge clk) begin
        AB <= sel;
        CS <= 0;
        LDAC <= 0;
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            d <= 8'b0000_0000;
            LED <= 8'b0101_0101;
        end
        else begin
            casex (btn_t)
                6'b1?????: d <= d - 8'b0000_0001;
                6'b01????: d <= d + 8'b0000_0001;
                6'b001???: d <= d - 8'b0000_0010;
                6'b0001??: d <= d + 8'b0000_0010;
                6'b00001?: d <= d - 8'b0000_1000;
                6'b000001: d <= d + 8'b0000_1000;
            endcase
            LED <= d;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) WR <= 1;
        else begin
            case (state)
                DELAY: WR <= 1;
                SET_WRN: WR <= 0;
                UP_DATA: WR <= d;
            endcase
        end
    end
endmodule

module one_shot_trigger #(
    parameter WIDTH = 12
)(
    input wire clk, rst,
    input wire [WIDTH-1:0] i,
    output reg [WIDTH-1:0] o
);
    reg [WIDTH-1:0] r;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            r <= {WIDTH{1'b0}};
            o <= {WIDTH{1'b0}};
        end
        else begin
            r <= i;
            o <= i & ~r;
        end
    end
endmodule
