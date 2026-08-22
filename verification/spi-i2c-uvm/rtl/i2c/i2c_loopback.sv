`timescale 1ns / 1ps

module i2c_loopback (
    input logic clk,
    input logic rst,
    input logic cmd_start,
    input logic cmd_write,
    input logic cmd_read,
    input logic cmd_stop,
    input logic [7:0] master_tx_data,
    input logic [7:0] slave_tx_data,
    output logic [7:0] master_rx_data,
    output logic [7:0] slave_rx_data,
    input logic ack_in,
    output logic ack_out,
    output logic busy,
    output logic master_done,
    output logic slave_done
);

    logic scl;
    wire sda;

    i2c_master_top U_I2C_MASTER_TOP (
        .*,
        .tx_data(master_tx_data),
        .rx_data(master_rx_data),

        .scl  (scl),
        .done(master_done),
        .sda  (sda)
    );

    i2c_slave_top #(
        .SLAVE_ADDR(7'h20)
    ) U_I2C_SLAVE_TOP (
        .clk(clk),
        .rst(rst),
        .tx_data(slave_tx_data),
        .rx_data(slave_rx_data),
        .done(slave_done),

        .scl(scl),
        .sda(sda)
    );
endmodule
