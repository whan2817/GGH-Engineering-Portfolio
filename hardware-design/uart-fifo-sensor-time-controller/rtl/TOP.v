module TOP (
    input        clk,
    input        rst,
    input        btnR,
    input        btnL,
    input        btnU,
    input        btnD,
    input        rx,
    input  [3:0] sw,
    output       tx,
    input        echo,

    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output [8:0] led,
    output       trig,

    inout dht11
);
    parameter MSEC_WIDTH = 7, SEC_WIDTH = 6, MIN_WIDTH = 6, HOUR_WIDTH = 5;
    wire w_rst_con;

    wire tx_busy;
    wire [MSEC_WIDTH - 1:0] w_msec_sw;
    wire [SEC_WIDTH  - 1:0] w_sec_sw;
    wire [MIN_WIDTH  - 1:0] w_min_sw;
    wire [HOUR_WIDTH - 1:0] w_hour_sw;

    wire [MSEC_WIDTH - 1:0] w_msec_wt;
    wire [SEC_WIDTH  - 1:0] w_sec_wt;
    wire [MIN_WIDTH  - 1:0] w_min_wt;
    wire [HOUR_WIDTH - 1:0] w_hour_wt;

    wire [MSEC_WIDTH - 1:0] w_msec;
    wire [SEC_WIDTH  - 1:0] w_sec;
    wire [MIN_WIDTH  - 1:0] w_min;
    wire [HOUR_WIDTH - 1:0] w_hour;

    wire w_runstop, w_clear, w_mode;
    wire w_set_mode, w_digit_sel;
    wire [1:0] w_time_sel, w_edit_cmd;
    wire w_btnR, w_btnL, w_btnD, w_btnU;
    wire w_btnR_con, w_btnL_con, w_btnD_con, w_btnU_con;


    wire [31:0] w_SW_data, w_WT_data, w_sr04_data, w_dht11_data;
    wire [31:0] w_mux_out;
    wire status;

    // 물리 버튼 입력을 Debounce한 뒤 UART 명령 기반 버튼 신호와 결합한다.
    button_debounce UBTNR (
        .clk  (clk),
        .rst  (w_rst_con),
        .i_btn(btnR),
        .o_btn(w_btnR)
    );
    button_debounce UBTNL (
        .clk  (clk),
        .rst  (w_rst_con),
        .i_btn(btnL),
        .o_btn(w_btnL)
    );
    button_debounce UBTNU (
        .clk  (clk),
        .rst  (w_rst_con),
        .i_btn(btnU),
        .o_btn(w_btnU)
    );
    button_debounce UBTND (
        .clk  (clk),
        .rst  (w_rst_con),
        .i_btn(btnD),
        .o_btn(w_btnD)
    );

    // UART RX와 TX가 공유하는 9,600 bps 기준 Tick을 생성한다.
    tick_gen #(
        .bps_value(9600),
        .F_COUNT  (100_000_000)
    ) U_TICK_9600 (
        .clk(clk),
        .rst(w_rst_con),
        .o_bps_tick(bps_tick)
    );

    wire       w_rx_push_fifo;
    wire [7:0] w_rx_data_fifo;
    wire [7:0] rx_pop_data;
    wire       w_rx_empty;
    wire       w_rx_full;


    // 수신 문자를 FIFO에 저장한 뒤 ASCII Decoder에서 제어 명령으로 변환한다.
    uart_rx #(
        .DATA_BIT(8)
    ) UART_RX (
        .clk    (clk),
        .rst    (w_rst_con),
        .bps    (bps_tick),
        .rx     (rx),
        .rx_done(w_rx_push_fifo),
        .rx_data(w_rx_data_fifo)
    );

    fifo #(
        .DEPTH(4)
    ) FIFO_RX (
        .clk      (clk),
        .rst      (w_rst_con),
        .push     (w_rx_push_fifo),
        .pop      (~rx_empty),
        .push_data(w_rx_data_fifo),
        .pop_data (rx_pop_data),
        .empty    (rx_empty),
        .full     (rx_full)
    );

    wire [5:0] button;
    
    button_con U_BUTTON_CON (
        .button_sel({button[5],button[3:0]}),
        .i_rst     (rst),
        .btnD      (w_btnD),
        .btnL      (w_btnL),
        .btnR      (w_btnR),
        .btnU      (w_btnU),
        .btnD_con  (w_btnD_con),
        .btnL_con  (w_btnL_con),
        .btnU_con  (w_btnU_con),
        .btnR_con  (w_btnR_con),
        .btnM_con  (w_rst_con)
    );


    ascii_decoder U_ASCII_DECODER (
        .clk(clk),
        .start(~rx_empty),
        .rst(w_rst_con),
        .UART_DATA(rx_pop_data),
        .button_sel(button)
    );


    assign status = button[4];
    
    wire o_mode;
    wire o_clear;
    wire o_runstop;
    wire o_set_mode;
    wire [1:0] o_timesel;
    wire o_digitsel;
    wire [1:0] o_edit;
    wire o_sr04_start;
    wire o_dht11_start;

    // 선택 모드와 통합 버튼 입력으로 시간 및 센서 Datapath를 제어한다.
    control u_control (
        .clk          (clk),
        .rst          (w_rst_con),
        .btnR         (w_btnR_con),
        .btnL         (w_btnL_con),
        .btnU         (w_btnU_con),
        .btnD         (w_btnD_con),
        .sw           (sw[3:1]),
        .o_mode       (o_mode),
        .o_clear      (o_clear),
        .o_runstop    (o_runstop),
        .o_set_mode   (o_set_mode),
        .o_timesel    (o_timesel),
        .o_digitsel   (o_digitsel),
        .o_edit       (o_edit),
        .o_sr04_start (o_sr04_start),
        .o_dht11_start(o_dht11_start),
        .led          (led[7:0])
    );


    wire w_tick_us;
    tick_gen_us TICK_US (
        .clk(clk),
        .rst(w_rst_con),
        .tick_us(w_tick_us)
    );

    wire [8:0] distance;
    // 공통 1 us Tick을 이용해 HC-SR04와 DHT11 프로토콜 시간을 측정한다.
    sr04_datapath U_SR04_DATAPATH (
        .clk(clk),
        .rst(w_rst_con),
        .btnR(o_sr04_start),
        .echo(echo),
        .tick_us(w_tick_us),
        .trig(trig),
        .distance(distance),
        .SR04_DONE(SR04_DONE)
    );

    wire [7:0] humidity_int, humidity_dec;
    wire [7:0] temperature_int, temperature_dec;
    dht11_datapath U_DHT11_DATAPATH (
        .clk            (clk),
        .rst            (w_rst_con),
        .dht11_start    (o_dht11_start),
        .tick_us        (w_tick_us),
        .humidity_int   (humidity_int),
        .humidity_dec   (humidity_dec),
        .temperature_int(temperature_int),
        .temperature_dec(temperature_dec),
        .valid          (led[8]),
        .dht11          (dht11)
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk      (clk),
        .rst      (w_rst_con),
        .i_runstop(o_runstop),
        .i_clear  (o_clear),
        .i_mode   (o_mode),
        .msec     (w_msec_sw),
        .sec      (w_sec_sw),
        .min      (w_min_sw),
        .hour     (w_hour_sw)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk(clk),
        .rst(w_rst_con),
        .i_set_mode (o_set_mode) ,
        .i_digit_sel(o_digitsel),
        .i_time_sel(o_timesel),
        .i_edit_cmd(o_edit),
        .msec(w_msec_wt),
        .sec(w_sec_wt),
        .min(w_min_wt),
        .hour(w_hour_wt)
    );
    wire [10:0] fnd_distance;
    spliter_distance u_spliter_distance (
        .distance(distance),
        .fnd_distance(fnd_distance)
    );

    // 네 기능의 출력을 32 bit 형식으로 정리하고 현재 모드의 데이터만 선택한다.
    assign w_SW_data = {
        {3'd0, w_hour_sw}, {2'd0, w_min_sw}, {2'd0, w_sec_sw}, {1'b0, w_msec_sw}
    };
    assign w_WT_data = {
        {3'd0, w_hour_wt}, {2'd0, w_min_wt}, {2'd0, w_sec_wt}, {1'b0, w_msec_wt}
    };
    assign w_sr04_data = {21'd0, fnd_distance[10:8], fnd_distance[7:0]};
    assign w_dht11_data = {
        humidity_int, humidity_dec, temperature_int, temperature_dec
    };

    mux_4x1_nbit #(
        .WIDTH(32)
    ) U_MUX4X1 (
        .clk(clk),
        .rst(w_rst_con),
        .in0(w_SW_data),
        .in1(w_WT_data),
        .in2(w_sr04_data),
        .in3(w_dht11_data),
        .sel(sw[3:2]),
        .y  (w_mux_out)
    );

    fnd_controller U_FND_CNTL (
        .clk     (clk),
        .rst     (w_rst_con),
        .sw      (sw[0]),
        .data    (w_mux_out),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

    wire [7:0] w_sender_data_fifo;
    wire w_sender_run_fifo;
    // 선택 데이터를 ASCII 문자열로 변환해 FIFO와 UART TX를 통해 PC로 전송한다.
    sender U_SENDER (
        .clk(clk),
        .rst(w_rst_con),
        .sw(sw[3:2]),
        .status(status),
        .in_data(w_mux_out),
        .run(w_sender_run_fifo),
        .out_data(w_sender_data_fifo)
    );
    wire [7:0] w_fifo_data_tx;
    wire tx_empty;

    wire tx_full;
    fifo #(
        .DEPTH(16)
    ) FIFO_TX (
        .clk      (clk),
        .rst      (w_rst_con),
        .push     (w_sender_run_fifo),
        .pop      (!tx_empty & !tx_busy),
        .push_data(w_sender_data_fifo),
        .pop_data (w_fifo_data_tx),
        .empty    (tx_empty),
        .full     (tx_full)
    );

    uart_tx #(
        .DATA_BIT(8)
    ) u_uart_tx (
        .clk     (clk),
        .bps     (bps_tick),
        .rst     (w_rst_con),
        .tx_start(~tx_empty),
        .data    (w_fifo_data_tx),
        .tx      (tx),
        .tx_busy (tx_busy)
    );
endmodule


module button_con (
    input [4:0] button_sel,
    input i_rst,
    input btnD,
    input btnL,
    input btnR,
    input btnU,
    output btnD_con,
    output btnL_con,
    output btnU_con,
    output btnR_con,
    output btnM_con
);

    assign btnD_con = btnD | button_sel[0];
    assign btnL_con = btnL | button_sel[1];
    assign btnR_con = btnR | button_sel[3];
    assign btnU_con = btnU | button_sel[4];
    assign btnM_con = i_rst | button_sel[2];


endmodule

