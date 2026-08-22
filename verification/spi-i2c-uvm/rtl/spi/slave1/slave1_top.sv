module slave1_top (
    input  logic       clk,
    input  logic       rst,
    input  logic       sclk,
    input  logic       mosi,
    output logic       miso,
    input  logic       ss_n,
    output logic [7:0] tx_data_led,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);
    logic [7:0] rx_data;
    logic       done;
    logic [7:0] o_data;

    assign fnd_com = 4'b1110;
    assign fnd_data = o_data;
    assign tx_data_led = o_data;

    spi_slave U_SPI_SLAVE (
        .clk    (clk),
        .rst    (rst),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .ss_n   (ss_n),
        .tx_data(o_data),
        .rx_data(rx_data),

        .done   (done)
    );

    fnd_rom U_FND_ROM(
        .clk(clk),
        .rst(rst),
        .i_btn(rx_data),
        .start (done),

        .o_data(o_data)
    );
endmodule
