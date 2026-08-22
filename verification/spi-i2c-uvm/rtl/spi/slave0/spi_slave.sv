`timescale 1ns / 1ps

module spi_slave (

    input logic clk,
    input logic rst,


    input  logic sclk,
    input  logic mosi,
    output logic miso,
    input  logic ss_n,


    input logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic busy,
    output logic done
);

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        DATA,
        STOP
    } slave_state_e;

    slave_state_e state;

    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [2:0] bit_cnt;
    logic miso_reg;

    assign miso = (ss_n) ? 1'bz : miso_reg;

    logic sclk_d1, sclk_d2;
    logic ss_n_d1, ss_n_d2;
    logic mosi_d1, mosi_d2;

    // 외부 SPI 신호를 시스템 클럭에 동기화해 안정적인 에지 검출에 사용한다.
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk_d1 <= 0;
            sclk_d2 <= 0;
            ss_n_d1 <= 1'b1;
            ss_n_d2 <= 1'b1;
            mosi_d1 <= 0;
            mosi_d2 <= 0;
        end else begin
            sclk_d1 <= sclk;
            sclk_d2 <= sclk_d1;
            ss_n_d1 <= ss_n;
            ss_n_d2 <= ss_n_d1;
            mosi_d1 <= mosi;
            mosi_d2 <= mosi_d1;
        end
    end


    assign sclk_rise = sclk_d1 & ~sclk_d2;
    assign sclk_fall = ~sclk_d1 & sclk_d2;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            miso_reg     <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            rx_data      <= 0;
            busy         <= 0;
            done         <= 0;
            bit_cnt      <= 0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    done <= 1'b0;
                    bit_cnt <= 0;
                    rx_shift_reg <= 0;
                    if(!ss_n_d2) begin
                        busy <= 1'b1;
                        tx_shift_reg <= tx_data;
                        miso_reg <= tx_shift_reg[7];
                        state <= DATA;

                    end
                end
                DATA: begin
                    busy <= 1'b1;
                    done <= 1'b0;
                    if (ss_n_d2) begin
                        state <= IDLE;
                        busy <= 1'b0;
                    end else begin


                        // Mode 0 기준으로 상승 에지에서 MOSI를 수신하고 하강 에지에서 MISO를 갱신한다.
                        if (sclk_rise) begin


                            rx_shift_reg <= {rx_shift_reg[6:0], mosi_d2};

                            if (bit_cnt == 7) begin

                                rx_data <= {rx_shift_reg[6:0], mosi_d2};
                                done <= 1'b1;
                                state <= STOP;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end


                        if (sclk_fall) begin

                            miso_reg <= tx_shift_reg[6];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        end
                    end
                end
                STOP: begin
                    done <= 1'b0;
                    if(ss_n_d2) begin
                        busy <= 1'b0;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
