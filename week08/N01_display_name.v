module display_name (
    input wire clk, rst,
    output wire E,
    output reg RS, RW,
    output reg [7:0] DATA, LED
);
    localparam DELAY = 3'b000;
    localparam FUNCTION_SET = 3'b001;
    localparam DISP_ONOFF = 3'b010;
    localparam ENTRY_MODE = 3'b011;
    localparam LINE1 = 3'b100;
    localparam LINE2 = 3'b101;
    localparam DELAY_T = 3'b110;
    localparam CLEAR_DISP = 3'b111;

    integer cnt;
    reg [2:0] state;

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
                        state <= LINE1;
                    end
                end
                LINE1: begin
                    LED <= 8'b0000_1000;
                    if (cnt >= 20) begin
                        cnt <= 0;
                        state <= LINE2;
                    end
                end
                LINE2: begin
                    LED <= 8'b0000_0100;
                    if (cnt >= 20) begin
                        cnt <= 0;
                        state <= DELAY_T;
                    end
                end
                DELAY_T: begin
                    LED <= 8'b0000_0010;
                    if (cnt >= 5) begin
                        cnt <= 0;
                        state <= CLEAR_DISP;
                    end
                end
                CLEAR_DISP: begin
                    LED <= 8'b0000_0001;
                    if (cnt >= 5) begin
                        cnt <= 0;
                        state <= LINE1;
                    end
                end
                default: state <= DELAY;
            endcase
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) {RS, RW, DATA} <= 10'b11_0000_0000;
        else begin
            case (state)
                FUNCTION_SET: {RS, RW, DATA} <= 10'b00_0011_1000;
                DISP_ONOFF: {RS, RW, DATA} <= 10'b00_0000_1100;
                ENTRY_MODE: {RS, RW, DATA} <= 10'b00_0000_0110;
                LINE1: begin
                    case (cnt)
                        00: {RS, RW, DATA} <= 10'b00_1000_0000;
                        01: {RS, RW, DATA} <= 10'b10_0010_0000; // 
                        02: {RS, RW, DATA} <= 10'b10_0100_1000; // H
                        03: {RS, RW, DATA} <= 10'b10_0110_0101; // e
                        04: {RS, RW, DATA} <= 10'b10_0110_1100; // l
                        05: {RS, RW, DATA} <= 10'b10_0110_1100; // l
                        06: {RS, RW, DATA} <= 10'b10_0110_1111; // o
                        07: {RS, RW, DATA} <= 10'b10_0010_0000; // 
                        08: {RS, RW, DATA} <= 10'b10_0111_0111; // w
                        09: {RS, RW, DATA} <= 10'b10_0110_1111; // o
                        10: {RS, RW, DATA} <= 10'b10_0111_0010; // r
                        11: {RS, RW, DATA} <= 10'b10_0110_1100; // l
                        12: {RS, RW, DATA} <= 10'b10_0110_0100; // d
                        13: {RS, RW, DATA} <= 10'b10_0010_0001; // !
                        default: {RS, RW, DATA} <= 10'b10_0010_0000;
                    endcase
                end
                LINE2: begin
                    case (cnt)
                        00: {RS, RW, DATA} <= 10'b00_1100_0000;
                        01: {RS, RW, DATA} <= 10'b10_0011_0010; // 2
                        02: {RS, RW, DATA} <= 10'b10_0011_0000; // 0
                        03: {RS, RW, DATA} <= 10'b10_0011_0010; // 2
                        04: {RS, RW, DATA} <= 10'b10_0011_0100; // 4
                        05: {RS, RW, DATA} <= 10'b10_0011_0100; // 4
                        06: {RS, RW, DATA} <= 10'b10_0011_0100; // 4
                        07: {RS, RW, DATA} <= 10'b10_0011_0000; // 0
                        08: {RS, RW, DATA} <= 10'b10_0011_0000; // 0
                        09: {RS, RW, DATA} <= 10'b10_0011_0101; // 5
                        10: {RS, RW, DATA} <= 10'b10_0011_0010; // 2
                        11: {RS, RW, DATA} <= 10'b10_0010_0000; // 
                        12: {RS, RW, DATA} <= 10'b10_0100_0100; // D
                        13: {RS, RW, DATA} <= 10'b10_0101_0011; // S
                        14: {RS, RW, DATA} <= 10'b10_0101_1001; // Y
                        default: {RS, RW, DATA} <= 10'b10_0010_0000;
                    endcase
                end
                DELAY_T: {RS, RW, DATA} <= 10'b00_0000_0010;
                CLEAR_DISP: {RS, RW, DATA} <= 10'b00_0000_0001;
                default: {RS, RW, DATA} <= 10'b11_0000_0000;
            endcase
        end
    end
endmodule
