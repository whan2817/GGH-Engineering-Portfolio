`timescale 1ns / 1ps

module uart_fifo_loopback (
    input  clk,
    input  rst,
    input  rx,
    output tx
);

    wire [7:0] w_rx_data, w_rx_pop_data, w_tx_pop_data;
    wire w_rx_done, w_tx_start, w_rx_pop_empty, w_tx_push_full, w_tx_pop_empty, w_tx_busy;

    uart U_UART (
        .clk     (clk),
        .rst     (rst),
        .tx_start(~w_tx_pop_empty),
        .tx_data (w_tx_pop_data),
        .rx      (rx),
        .rx_data (w_rx_data),
        .rx_done (w_rx_done),
        .tx_busy (w_tx_busy),
        .tx      (tx)
    );

    // 수신 데이터는 RX FIFO를 거쳐 TX FIFO로 전달된다.
    fifo U_FIFO_RX (
        .clk      (clk),
        .rst      (rst),
        .push_data(w_rx_data),
        .push     (w_rx_done),
        .pop      (~w_tx_push_full),
        .pop_data (w_rx_pop_data),
        .full     (),
        .empty    (w_rx_pop_empty)
    );

    fifo U_FIFO_TX (
        .clk      (clk),
        .rst      (rst),
        .push_data(w_rx_pop_data),
        .push     (~w_rx_pop_empty),
        .pop      (~w_tx_busy),
        .pop_data (w_tx_pop_data),
        .full     (w_tx_push_full),
        .empty    (w_tx_pop_empty)
    );

endmodule
