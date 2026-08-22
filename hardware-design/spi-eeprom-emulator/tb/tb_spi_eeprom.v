`timescale 1ns / 1ps

module tb_spi_eeprom_slave;

    


    reg         clk;
    reg         rst;

    reg         sclk;
    reg         mosi;
    wire        miso;
    reg         cs_n;

    wire [15:0] led;

    


    localparam integer CLK_PERIOD_NS  = 10;
    localparam integer SCLK_HALF_NS   = 50;

    


    integer pass_count;
    integer fail_count;

    


    spi_eeprom_top DUT (
        .clk    (clk),
        .rst    (rst),

        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .cs_n   (cs_n),

        .led    (led)
    );

    


    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD_NS / 2) clk = ~clk;
    end

    


    // SPI Mode 0 타이밍으로 한 바이트를 전송하면서 MISO 응답을 함께 수집한다.
    task spi_transfer_byte;
        input  [7:0] tx_byte;
        output [7:0] rx_byte;
        integer i;
        begin
            rx_byte = 8'h00;

            for (i = 7; i >= 0; i = i - 1) begin
                


                mosi = tx_byte[i];

                #(SCLK_HALF_NS);

                


                sclk = 1'b1;

                #1;
                rx_byte[i] = miso;

                #(SCLK_HALF_NS - 1);

                


                sclk = 1'b0;
            end

            


            #(SCLK_HALF_NS);
        end
    endtask

    


    task eeprom_write_byte;
        input [7:0] addr;
        input [7:0] data;
        reg   [7:0] dummy;
        begin
            $display("[WRITE] addr=0x%02X data=0x%02X", addr, data);

            cs_n = 1'b0;
            #(SCLK_HALF_NS);

            spi_transfer_byte(8'h02, dummy);   
            spi_transfer_byte(addr,  dummy);   
            spi_transfer_byte(data,  dummy);   

            cs_n = 1'b1;
            #(SCLK_HALF_NS * 2);
        end
    endtask

    


    task eeprom_read_byte;
        input  [7:0] addr;
        output [7:0] data;
        reg    [7:0] dummy;
        begin
            cs_n = 1'b0;
            #(SCLK_HALF_NS);

            spi_transfer_byte(8'h03, dummy);   
            spi_transfer_byte(addr,  dummy);   
            spi_transfer_byte(8'h00, data);    

            cs_n = 1'b1;
            #(SCLK_HALF_NS * 2);

            $display("[READ ] addr=0x%02X data=0x%02X", addr, data);
        end
    endtask

    


    task eeprom_write_3bytes;
        input [7:0] start_addr;
        input [7:0] data0;
        input [7:0] data1;
        input [7:0] data2;
        reg   [7:0] dummy;
        begin
            $display("[SEQ WRITE] start_addr=0x%02X data=0x%02X 0x%02X 0x%02X",
                     start_addr, data0, data1, data2);

            cs_n = 1'b0;
            #(SCLK_HALF_NS);

            spi_transfer_byte(8'h02,      dummy);  
            spi_transfer_byte(start_addr, dummy);  
            spi_transfer_byte(data0,      dummy);  
            spi_transfer_byte(data1,      dummy);  
            spi_transfer_byte(data2,      dummy);  

            cs_n = 1'b1;
            #(SCLK_HALF_NS * 2);
        end
    endtask

    


    task eeprom_read_3bytes;
        input  [7:0] start_addr;
        output [7:0] data0;
        output [7:0] data1;
        output [7:0] data2;
        reg    [7:0] dummy;
        begin
            cs_n = 1'b0;
            #(SCLK_HALF_NS);

            spi_transfer_byte(8'h03,      dummy);  
            spi_transfer_byte(start_addr, dummy);  
            spi_transfer_byte(8'h00,      data0);  
            spi_transfer_byte(8'h00,      data1);  
            spi_transfer_byte(8'h00,      data2);  

            cs_n = 1'b1;
            #(SCLK_HALF_NS * 2);

            $display("[SEQ READ ] start_addr=0x%02X data=0x%02X 0x%02X 0x%02X",
                     start_addr, data0, data1, data2);
        end
    endtask

    


    task check_equal;
        input [8*32-1:0] test_name;
        input [7:0]      expected;
        input [7:0]      actual;
        begin
            if (expected == actual) begin
                $display("[PASS] %0s expected=0x%02X actual=0x%02X",
                         test_name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s expected=0x%02X actual=0x%02X",
                         test_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    


    reg [7:0] rd_data;
    reg [7:0] rd0;
    reg [7:0] rd1;
    reg [7:0] rd2;

    initial begin
        pass_count = 0;
        fail_count = 0;

        


        rst  = 1'b1;
        sclk = 1'b0;
        mosi = 1'b0;
        cs_n = 1'b1;

        $display("========================================");
        $display(" SPI EEPROM Emulator Testbench Start");
        $display("========================================");

        #(CLK_PERIOD_NS * 10);

        


        rst = 1'b0;
        #(CLK_PERIOD_NS * 10);

        


        $display("\n[Test 1] Initial memory read");
        eeprom_read_byte(8'h10, rd_data);
        check_equal("Initial Read addr 0x10", 8'h10, rd_data);

        


        $display("\n[Test 2] Single write/read");
        eeprom_write_byte(8'h10, 8'hA5);
        eeprom_read_byte (8'h10, rd_data);
        check_equal("Single Write/Read addr 0x10", 8'hA5, rd_data);

        


        $display("\n[Test 3] Single write/read another address");
        eeprom_write_byte(8'h33, 8'h5A);
        eeprom_read_byte (8'h33, rd_data);
        check_equal("Single Write/Read addr 0x33", 8'h5A, rd_data);

        


        $display("\n[Test 4] Sequential write/read");
        eeprom_write_3bytes(8'h20, 8'hAA, 8'h55, 8'hC3);
        eeprom_read_3bytes (8'h20, rd0, rd1, rd2);

        check_equal("Sequential Read addr 0x20", 8'hAA, rd0);
        check_equal("Sequential Read addr 0x21", 8'h55, rd1);
        check_equal("Sequential Read addr 0x22", 8'hC3, rd2);

        


        $display("\n========================================");
        $display(" SPI EEPROM Emulator Test Result");
        $display(" PASS = %0d", pass_count);
        $display(" FAIL = %0d", fail_count);
        $display("========================================");

        if (fail_count == 0) begin
            $display("[FINAL RESULT] ALL PASS");
        end else begin
            $display("[FINAL RESULT] FAIL DETECTED");
        end

        #(CLK_PERIOD_NS * 20);
        $finish;
    end

endmodule
