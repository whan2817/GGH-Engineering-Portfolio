`include "uvm_macros.svh"
import uvm_pkg::*;
import spi_pkg::*;


module tb_top ();
    logic clk;
    logic rst;

initial begin
        $fsdbDumpfile("spi_tb.fsdb");
        $fsdbDumpvars(0);
        $fsdbDumpMDA();
    end

    initial begin
        clk = 0;
        rst = 1;
        #20;
        rst = 0;
    end
    always #5 clk = ~clk;

    spi_interface spi_if(clk, rst);

    spi dut (
        .clk       (spi_if.clk),
        .rst       (spi_if.rst),
        .start     (spi_if.start),
        .cpol      (spi_if.cpol),
        .cpha      (spi_if.cpha),
        .clk_div   (8'd9),
        .slave_sel (spi_if.slave_sel),
        .m_tx_data (spi_if.m_tx_data),
        .s0_tx_data(spi_if.s0_tx_data),
        .s1_tx_data(spi_if.s1_tx_data),
        .m_rx_data (spi_if.m_rx_data),
        .s0_rx_data(spi_if.s0_rx_data),
        .s1_rx_data(spi_if.s1_rx_data),
        .m_busy    (spi_if.m_busy),
        .m_done    (spi_if.m_done),
        .s0_done   (spi_if.s0_done),
        .s1_done   (spi_if.s1_done),
        .sclk      (spi_if.sclk),
        .mosi      (spi_if.mosi),
        .miso      (spi_if.miso),
        .ss_n      (spi_if.ss_n)
    );

    initial begin
        uvm_config_db#(virtual spi_interface)::set(null, "*", "spi_if", spi_if);
        run_test("spi_test");
    end

endmodule

