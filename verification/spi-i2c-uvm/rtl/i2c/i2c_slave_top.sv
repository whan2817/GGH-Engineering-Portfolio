`timescale 1ns / 1ps

module i2c_slave_top #(
    parameter [6:0] SLAVE_ADDR = 7'h20
) (
    input logic clk,
    input logic rst,

    input logic scl,
    inout logic sda,

    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       done
);
    logic sda_i, sda_o;
    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;

    i2c_slave #(.SLAVE_ADDR(7'h20)) U_SLAVE_1 (.*);
endmodule

module i2c_slave #(
    parameter [6:0] SLAVE_ADDR = 7'h20
) (
    input logic clk,
    input logic rst,

    input  logic scl,
    input  logic sda_i,
    output logic sda_o,

    output logic [7:0] rx_data,
    input  logic [7:0] tx_data,
    output logic       done
);

    typedef enum logic [2:0] {
        IDLE,
        RX_ADDR,
        ACK_ADDR,
        RX_DATA,
        ACK_DATA,
        TX_DATA,
        WAIT_ACK
    } state_e;
    state_e       state;

    logic   [7:0] shift_reg;
    logic   [2:0] bit_cnt;
    logic         is_read;


    logic scl_d1, scl_d2;
    logic sda_d1, sda_d2;

    // 비동기 I2C 입력을 두 단계로 동기화해 에지와 START/STOP 조건을 검출한다.
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_d1 <= 1'b1;
            scl_d2 <= 1'b1;
            sda_d1 <= 1'b1;
            sda_d2 <= 1'b1;
        end else begin
            scl_d1 <= scl;
            scl_d2 <= scl_d1;
            sda_d1 <= sda_i;
            sda_d2 <= sda_d1;
        end
    end


    logic scl_rise, scl_fall;
    logic sda_rise, sda_fall;
    assign scl_rise = ~scl_d2 & scl_d1;
    assign scl_fall = scl_d2 & ~scl_d1;
    assign sda_rise = ~sda_d2 & sda_d1;
    assign sda_fall = sda_d2 & ~sda_d1;


    logic start_cond, stop_cond;
    assign start_cond = scl_d2 & sda_fall;
    assign stop_cond  = scl_d2 & sda_rise;

    // 주소의 R/W 비트에 따라 수신 또는 송신 경로로 분기하고 ACK를 처리한다.
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state   <= IDLE;
            sda_o   <= 1'b1;
            bit_cnt <= 0;
            rx_data <= 0;
            is_read <= 0;
            done    <= 1'b0;
        end else begin
            done <= 1'b0;
            if (start_cond) begin
                state   <= RX_ADDR;
                bit_cnt <= 0;
                sda_o   <= 1'b1;
            end else if (stop_cond) begin
                state <= IDLE;
                sda_o <= 1'b1;
            end else begin
                case (state)
                    IDLE: begin
                        sda_o <= 1'b1;
                    end
                    RX_ADDR: begin
                        if (scl_rise) begin
                            shift_reg <= {shift_reg[6:0], sda_d2};
                            if (bit_cnt == 7) begin
                                if (shift_reg[6:0] == SLAVE_ADDR) begin


                                    state   <= ACK_ADDR;
                                    is_read <= sda_d2;

                                end else begin
                                    state <= IDLE;
                                end
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                    ACK_ADDR: begin
                        if (scl_fall) begin
                            sda_o <= 1'b0;
                        end
                        if (scl_rise) begin
                            if (is_read) begin
                                state     <= TX_DATA;
                                shift_reg <= tx_data;
                                bit_cnt   <= 0;
                            end else begin
                                state   <= RX_DATA;
                                bit_cnt <= 0;
                            end
                        end
                    end
                    RX_DATA: begin
                        if (scl_fall) begin
                            sda_o <= 1'b1;
                        end
                        if (scl_rise) begin
                            shift_reg <= {shift_reg[6:0], sda_d2};
                            if (bit_cnt == 7) begin
                                rx_data <= {shift_reg[6:0], sda_d2};
                                done    <= 1'b1;
                                state   <= ACK_DATA;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                    ACK_DATA: begin
                        if (scl_fall) begin
                            sda_o <= 1'b0;
                        end
                        if (scl_rise) begin
                            state   <= RX_DATA;
                            bit_cnt <= 0;
                        end
                    end
                    TX_DATA: begin
                        if (scl_fall) begin
                            sda_o     <= shift_reg[7];
                            shift_reg <= {shift_reg[6:0], 1'b0};
                        end
                        if (scl_rise) begin
                            if (bit_cnt == 7) begin
                                state <= WAIT_ACK;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                    WAIT_ACK: begin
                        if (scl_fall) begin
                            sda_o <= 1'b1;
                        end
                        if (scl_rise) begin
                            if (sda_d2 == 1'b0) begin
                                state     <= TX_DATA;
                                shift_reg <= tx_data;
                                bit_cnt   <= 0;
                            end else begin
                                state <= IDLE;
                            end
                        end
                    end
                    default: state <= IDLE;
                endcase
            end
        end
    end
endmodule
