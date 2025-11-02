module cursor (
    input wire clk, rst, sel,
    input wire [9:0] num,
    input wire [1:0] ctrl,
    output wire E,
    output reg RS, RW,
    output reg [7:0] DATA, LED
);
    localparam DELAY = 3'b000;
    localparam FUNCTION_SET = 3'b001;
    localparam DISP_ONOFF = 3'b010;
    localparam ENTRY_MODE = 3'b011;
    localparam SET_ADDRESS = 3'b100;
    localparam DELAY_T = 3'b101;
    localparam WRITE = 3'b110;
    localparam CURSOR = 3'b111;

    wire [9:0] num_t;
    wire [1:0] ctrl_t;
    wire sel_rise, sel_fall;

    reg [7:0] cnt;
    reg [2:0] state;
    reg [6:0] addr;

    one_shot_trigger #(.WIDTH(12)) ost1 (clk, rst, {num, ctrl}, {num_t, ctrl_t});
    one_shot_trigger #(.WIDTH(2)) ost2 (clk, rst, {sel, ~sel}, {sel_rise, sel_fall});

    assign E = clk;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cnt <= 0;
            state <= DELAY;
        end
        else begin
            cnt <= cnt + 1;
            case (state)
                DELAY: begin
                    LED <= 8'b1000_0000;
                    if (cnt >= 70) begin
                        cnt <= 0;
                        state <= FUNCTION_SET;
                    end
                end
                FUNCTION_SET: begin
                    LED <= 8'b0100_0000;
                    if (cnt >= 30) begin
                        cnt <= 0;
                        state <= DISP_ONOFF;
                    end
                end
                DISP_ONOFF: begin
                    LED <= 8'b0010_0000;
                    if (cnt >= 30) begin
                        cnt <= 0;
                        state <= ENTRY_MODE;
                    end
                end
                ENTRY_MODE: begin
                    LED <= 8'b0001_0000;
                    if (cnt >= 30) begin
                        cnt <= 0;
                        state <= SET_ADDRESS;
                    end
                end
                SET_ADDRESS: begin
                    LED <= 8'b0000_1000;
                    if (cnt >= 100) begin
                        cnt <= 0;
                        state <= DELAY_T;
                        addr <= 7'h00;
                    end
                end
                DELAY_T: begin
                    LED <= 8'b0000_0100;
                    cnt <= 0;
                    state <= |num_t ? WRITE : (|ctrl_t ? CURSOR : DELAY_T);
                end
                WRITE: begin
                    LED <= 8'b0000_0010;
                    if (cnt >= 30) begin
                        cnt <= 0;
                        state <= DELAY_T;
                        case (addr)
                            7'h0F: addr <= 7'h40;
                            7'h4F: addr <= 7'h00;
                            default: addr <= addr + 1;
                        endcase
                    end
                end
                CURSOR: begin
                    LED <= 8'b0000_0001;
                    if (cnt >= 30) begin
                        cnt <= 0;
                        state <= DELAY_T;
                        case (ctrl)
                            2'b10: begin
                                case (addr)
                                    7'h00: addr <= 7'h4F;
                                    7'h40: addr <= 7'h0F;
                                    default: addr <= addr - 1;
                                endcase
                            end
                            2'b01: begin
                                case (addr)
                                    7'h0F: addr <= 7'h40;
                                    7'h4F: addr <= 7'h00;
                                    default: addr <= addr + 1;
                                endcase
                            end
                        endcase
                    end
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) {RS, RW, DATA} <= 10'b00_0000_0001;
        else begin
            case (state)
                FUNCTION_SET: {RS, RW, DATA} <= 10'b00_0011_1000;
                DISP_ONOFF: {RS, RW, DATA} <= 10'b00_0000_1111;
                ENTRY_MODE: {RS, RW, DATA} <= 10'b00_0000_0110;
                SET_ADDRESS: {RS, RW, DATA} <= 10'b00_0000_0010;
                DELAY_T: begin
                    case ({sel_rise, sel_fall})
                        2'b01: {RS, RW, DATA} <= 10'b00_1000_0000;
                        2'b10: {RS, RW, DATA} <= 10'b00_1100_0000;
                        default: {RS, RW, DATA} <= 10'b00_0000_1111;
                    endcase
                end
                WRITE: begin
                    if (cnt == 20) begin
                        case (num)
                            10'b10_0000_0000: {RS, RW, DATA} <= 10'b10_0011_0001; // 1
                            10'b01_0000_0000: {RS, RW, DATA} <= 10'b10_0011_0010; // 2
                            10'b00_1000_0000: {RS, RW, DATA} <= 10'b10_0011_0011; // 3
                            10'b00_0100_0000: {RS, RW, DATA} <= 10'b10_0011_0100; // 4
                            10'b00_0010_0000: {RS, RW, DATA} <= 10'b10_0011_0101; // 5
                            10'b00_0001_0000: {RS, RW, DATA} <= 10'b10_0011_0110; // 6
                            10'b00_0000_1000: {RS, RW, DATA} <= 10'b10_0011_0111; // 7
                            10'b00_0000_0100: {RS, RW, DATA} <= 10'b10_0011_1000; // 8
                            10'b00_0000_0010: {RS, RW, DATA} <= 10'b10_0011_1001; // 9
                            10'b00_0000_0001: {RS, RW, DATA} <= 10'b10_0011_0000; // 0
                            default: {RS, RW, DATA} <= 10'b10_0010_0000; // 
                        endcase
                    end
                    else if (cnt == 25) begin
                        case (addr)
                            7'h10: {RS, RW, DATA} <= 10'b00_1000_0000 + 7'h40;
                            7'h50: {RS, RW, DATA} <= 10'b00_1000_0000 + 7'h00;
                        endcase
                    end
                    else {RS, RW, DATA} <= 10'b00_0000_1111;
                end
                CURSOR: begin
                    if (cnt == 20) begin
                        case (ctrl)
                            2'b10: begin
                                case (addr)
                                    7'h00: {RS, RW, DATA} <= 10'b00_1000_0000 + 7'h4F;
                                    7'h40: {RS, RW, DATA} <= 10'b00_1000_0000 + 7'h0F;
                                    default: {RS, RW, DATA} <= 10'b00_0001_0000; // left
                                endcase
                            end
                            2'b01: begin
                                case (addr)
                                    7'h0F: {RS, RW, DATA} <= 10'b00_1000_0000 + 7'h40;
                                    7'h4F: {RS, RW, DATA} <= 10'b00_1000_0000 + 7'h00;
                                    default: {RS, RW, DATA} <= 10'b00_0001_0100; // right
                                endcase
                            end
                        endcase
                    end
                    else {RS, RW, DATA} <= 10'b00_0000_1111;
                end
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
