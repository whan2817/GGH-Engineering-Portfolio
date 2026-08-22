`timescale 1ns / 1ps

module slave0_top (
    input  logic       clk,
    input  logic       rst,
    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    input  logic       ss_n,
    output logic [7:0] rx_data_led,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data,
    output logic       led
);

    logic [7:0] rx_data;
    logic done_pulse;
    logic led_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) led_reg <= 1'b0;
        else if (done_pulse) led_reg <= ~led_reg;
    end

    assign led = led_reg;

    assign rx_data_led = rx_data;

    spi_slave U_SPI_SLAVE (
        .clk    (clk),
        .rst    (rst),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .ss_n   (ss_n),
        .tx_data(fnd_data),
        .rx_data(rx_data),
        .busy   (),
        .done   (done_pulse)
    );

    counter_ip U_SLAVE_IP (
        .clk     (clk),
        .rst     (rst),
        .start   (done_pulse),
        .slave_in(rx_data),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

endmodule

