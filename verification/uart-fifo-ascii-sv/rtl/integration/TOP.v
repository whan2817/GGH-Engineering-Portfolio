module TOP (
    input  clk,
    input  rst,
    input  rx,
    output tx
);

    // 통합 테스트벤치의 최상위 포트와 Loopback 모듈을 연결한다.
    uart_fifo_loopback U_UART_FIFO_LOOPBACK (
        .clk(clk),
        .rst(rst),
        .rx (rx),
        .tx (tx)
    );

endmodule
