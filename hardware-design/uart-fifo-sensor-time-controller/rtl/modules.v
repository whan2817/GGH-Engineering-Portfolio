`timescale 1ns / 1ps

module button_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);


    parameter F_COUNT = 100_000_000 / 1000;
    // 버튼 입력을 저속으로 샘플링해 접점 진동을 제거할 기준 신호를 만든다.
    reg [$clog2(F_COUNT) - 1 : 0] r_counter;
    reg clk_100khz;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter  <= 1'b0;
            clk_100khz <= 1'b0;
        end else begin
            r_counter <= r_counter + 1'b1;
            if (r_counter == F_COUNT - 1) begin
                r_counter  <= 1'b0;
                clk_100khz <= 1'b1;
            end else begin
                clk_100khz <= 1'b0;
            end
        end
    end

    // 비동기 버튼 입력을 연속 샘플링해 안정된 입력만 유효한 버튼으로 판단한다.
    reg [7:0] sync_reg, sync_next;
    reg  edge_reg;
    wire debounce;

    always @(posedge clk_100khz, posedge rst) begin
        if (rst) begin
            sync_reg <= 0;
        end else begin
            sync_reg <= sync_next;
        end
    end
    always @(*) begin
        sync_next = {i_btn, sync_reg[7:1]};
    end

    assign debounce = &sync_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end
    assign o_btn = debounce & (~edge_reg);
endmodule


module mux_4x1_nbit #(
    parameter WIDTH = 32
) (
    input                      clk,
    input                      rst,
    input      [WIDTH - 1 : 0] in0,
    input      [WIDTH - 1 : 0] in1,
    input      [WIDTH - 1 : 0] in2,
    input      [WIDTH - 1 : 0] in3,
    input      [          1:0] sel,
    output reg [WIDTH - 1 : 0] y
);
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            y <= 0;
        end else begin
            if (sel == 2'b00) begin
                y <= in0;
            end
            if (sel == 2'b01) begin
                y <= in1;
            end
            if (sel == 2'b10) begin
                y <= in2;
            end
            if (sel == 2'b11) begin
                y <= in3;
            end
        end
    end
endmodule

module ascii_decoder (
    input clk,
    input start,
    input rst,
    input [7:0] UART_DATA,
    output reg [5:0] button_sel
    );
    localparam IDLE = 0, DATA = 1;
    reg state;
    reg [7:0] UART_DATA_buf;
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            button_sel <= 0;
            UART_DATA_buf <= 0;
        end else begin
            case (state)
                IDLE: begin
                    button_sel <= 0;
                    UART_DATA_buf <= UART_DATA;
                    if (start) state <= DATA;
                    else state <= IDLE;
                end
                DATA: begin
                    state <= IDLE;
                    UART_DATA_buf <= UART_DATA_buf;
                    // 대소문자 명령을 동일한 6 bit 버튼 선택 신호로 변환한다.
                    case (UART_DATA_buf)
                        8'h44:   button_sel <= 6'b000001;
                        8'h4C:   button_sel <= 6'b000010;
                        8'h4D:   button_sel <= 6'b000100;
                        8'h52:   button_sel <= 6'b001000;
                        8'h53:   button_sel <= 6'b010000;
                        8'h55:   button_sel <= 6'b100000;
                        8'h64:   button_sel <= 6'b000001;
                        8'h6C:   button_sel <= 6'b000010;
                        8'h6D:   button_sel <= 6'b000100;
                        8'h72:   button_sel <= 6'b001000;
                        8'h73:   button_sel <= 6'b010000;
                        8'h75:   button_sel <= 6'b100000;
                        default: button_sel <= 0;
                    endcase
                end
                default: begin

                end
            endcase
        end
    end
endmodule

module spliter_distance (
    input  [ 8:0] distance,
    output [10:0] fnd_distance
);
    assign fnd_distance[10:8] = distance / 100;
    assign fnd_distance[7:0]  = distance % 100;

endmodule
