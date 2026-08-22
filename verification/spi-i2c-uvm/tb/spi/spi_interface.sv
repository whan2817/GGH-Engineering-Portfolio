interface spi_interface(input logic clk, input logic rst);

    logic       start;
    logic       cpol;
    logic       cpha;
    logic [7:0] clk_div;
    logic       slave_sel;

    logic [7:0] m_tx_data;
    logic [7:0] s0_tx_data;
    logic [7:0] s1_tx_data;
    logic [7:0] m_rx_data;
    logic [7:0] s0_rx_data;
    logic [7:0] s1_rx_data;

    logic       m_busy;
    logic       m_done;
    logic       s0_done;
    logic       s1_done;

    logic       sclk;
    logic       mosi;
    logic       miso;
    logic [1:0] ss_n;

    // 드라이버와 모니터의 구동 및 샘플링 시점을 clocking block으로 분리한다.
    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        output start;
        output cpol;
        output cpha;
        output clk_div;
        output slave_sel;
        output m_tx_data;
        output s0_tx_data;
        output s1_tx_data;
        input  m_rx_data;
        input  s0_rx_data;
        input  s1_rx_data;
        input  m_busy;
        input  m_done;
        input  s0_done;
        input  s1_done;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input start;
        input cpol;
        input cpha;
        input clk_div;
        input slave_sel;
        input m_tx_data;
        input s0_tx_data;
        input s1_tx_data;
        input m_rx_data;
        input s0_rx_data;
        input s1_rx_data;
        input m_busy;
        input m_done;
        input s0_done;
        input s1_done;
    endclocking

    modport DRV(clocking drv_cb, input clk, input rst);
    modport MON(clocking mon_cb, input clk, input rst);
endinterface
