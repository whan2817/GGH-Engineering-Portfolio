`timescale 1ns / 1ps

module spi_eeprom_top(
    input  wire        clk,      
    input  wire        rst,      

    input  wire        sclk,     
    input  wire        mosi,     
    output wire        miso,     
    input  wire        cs_n,     

    output wire [15:0] led       
);

    wire [7:0] last_cmd;
    wire [7:0] last_addr;
    wire [7:0] last_data;
    wire [1:0] dbg_state;

    spi_eeprom_emulator U_SPI_EEPROM_EMULATOR (
        .clk       (clk),
        .rst       (rst),
        .sclk      (sclk),
        .mosi      (mosi),
        .miso      (miso),
        .cs_n      (cs_n),

        .last_cmd  (last_cmd),
        .last_addr (last_addr),
        .last_data (last_data),
        .dbg_state (dbg_state)
    );

    


    assign led[7:0]   = last_data;
    assign led[11:8]  = last_addr[3:0];
    assign led[13:12] = dbg_state;
    assign led[14]    = ~cs_n;
    assign led[15]    = rst;

endmodule


