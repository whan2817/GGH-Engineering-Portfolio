`timescale 1ns / 1ps

module uart_fifo_decoder (
    input        clk,
    input        rst,
    input        rx,
    output [5:0] button_sel
);

    wire       w_b_tick;
    wire [7:0] w_rx_data;
    wire       w_rx_done;

    wire [7:0] w_fifo_data;
    wire       w_fifo_full;
    wire       w_fifo_empty;
    wire       w_fifo_pop;

    reg  [7:0] r_decoder_data;
    reg        r_decoder_start;
    reg        r_decoder_wait;

    // UART 수신을 위한 16배 오버샘플링 기준 틱을 생성한다.
    baud_tick_gen U_BAUD_TICK_GEN (
        .clk     (clk),
        .rst     (rst),
        .o_b_tick(w_b_tick)
    );

    uart_rx U_UART_RX (
        .clk    (clk),
        .rst    (rst),
        .b_tick (w_b_tick),
        .rx     (rx),
        .rx_done(w_rx_done),
        .rx_data(w_rx_data)
    );

    // 수신 데이터와 디코더의 처리 시점을 분리하기 위해 FIFO에 저장한다.
    fifo U_FIFO (
        .clk      (clk),
        .rst      (rst),
        .push_data(w_rx_data),
        .push     (w_rx_done),
        .pop      (w_fifo_pop),
        .pop_data (w_fifo_data),
        .full     (w_fifo_full),
        .empty    (w_fifo_empty)
    );

    assign w_fifo_pop = (~r_decoder_wait) & (~w_fifo_empty);

    // FIFO 데이터를 고정한 뒤 디코더 시작 신호를 한 클럭 동안 전달한다.
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_decoder_data  <= 0;
            r_decoder_start <= 0;
            r_decoder_wait  <= 0;
        end else begin
            r_decoder_start <= w_fifo_pop;

            if (w_fifo_pop) begin
                r_decoder_data <= w_fifo_data;
                r_decoder_wait <= 1;
            end else if (r_decoder_wait) begin
                r_decoder_wait <= 0;
            end
        end
    end

    ascii_decoder U_ASCII_DECODER (
        .clk       (clk),
        .start     (r_decoder_start),
        .rst       (rst),
        .UART_DATA (r_decoder_data),
        .button_sel(button_sel)
    );

endmodule
