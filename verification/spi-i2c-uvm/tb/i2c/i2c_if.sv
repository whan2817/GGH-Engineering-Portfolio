interface i2c_if (
    input logic clk
);
    logic rst;

    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;

    logic [7:0] master_tx_data;
    logic [7:0] slave_tx_data;

    logic [7:0] master_rx_data;
    logic [7:0] slave_rx_data;

    logic busy;
    logic master_done;
    logic slave_done;

    // 드라이버와 모니터의 구동 및 샘플링 시점을 clocking block으로 분리한다.
    clocking drv_cb @(posedge clk);
        default input #1step output #0;

        output rst;

        output cmd_start;
        output cmd_write;
        output cmd_read;
        output cmd_stop;

        output master_tx_data;
        output slave_tx_data;

        input master_rx_data;
        input slave_rx_data;

        input busy;
        input master_done;
        input slave_done;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;

        input rst;

        input cmd_start;
        input cmd_write;
        input cmd_read;
        input cmd_stop;

        input master_tx_data;
        input slave_tx_data;

        input master_rx_data;
        input slave_rx_data;

        input busy;
        input master_done;
        input slave_done;
    endclocking

    modport DRV (clocking drv_cb, input clk);
    modport MON (clocking mon_cb, input clk);

endinterface
