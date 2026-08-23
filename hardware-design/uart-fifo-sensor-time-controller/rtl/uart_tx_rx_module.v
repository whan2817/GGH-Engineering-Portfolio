
module uart_tx #(
    parameter DATA_BIT = 8
) (
    input clk,
    input bps,
    input rst,
    input tx_start,
    input [DATA_BIT-1:0] data,
    output reg tx,
    output reg tx_busy
);
    localparam IDLE = 0, START = 1, S0 = 2;
    reg [1:0] state;
    reg [DATA_BIT:0] data_reg;
    reg [3:0] bps_count;
    reg bps_tick;

    // 16배 오버샘플링 Tick을 실제 UART 비트 경계로 변환한다.
    always @(*) begin
        if (bps) begin
            if (bps_count >= 4'd15) begin
                bps_tick = 1;
            end else begin
                bps_tick = 0;
            end
        end else begin
            bps_tick = 0;
        end
    end

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            bps_count <= 0;
        end else begin
            if (bps) begin
                if (bps_count >= 4'd15) begin
                    bps_count <= 0;
                end else begin
                    bps_count <= bps_count + 1;
                end
            end else begin
                bps_count <= bps_count;
            end
        end
    end

    // Start bit, 8 bit 데이터, Stop bit를 순서대로 직렬화한다.
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx <= 1;
            data_reg <= {1'b1, data};
            tx_busy <= 0;
        end else begin
            case (state)
                IDLE: begin
                    data_reg <= {1'b0, data};
                    if (tx_start) begin
                        state <= START;
                        tx <= 1;
                        tx_busy <= 1;
                    end else begin
                        state <= IDLE;
                        tx <= 1;
                        tx_busy <= 0;
                    end
                end
                START: begin
                    tx_busy  <= 1;
                    data_reg <= data_reg;
                    if (bps_tick) begin
                        state <= S0;
                        tx <= 0;
                    end else begin
                        state <= START;
                        tx <= 1;
                    end
                end
                S0: begin
                    if (bps_tick) begin
                        if (!(&data_reg[DATA_BIT:1])) begin
                            state <= S0;
                            tx <= data_reg[0];
                            data_reg <= {1'b1, data_reg[DATA_BIT:1]};
                            tx_busy <= 1;
                        end else begin
                            state <= IDLE;
                            tx <= 1'b1;
                            data_reg <= {1'b1, data};
                            tx_busy <= 0;
                        end
                    end else begin
                        state <= state;
                        tx <= tx;
                        data_reg <= data_reg;
                        tx_busy <= 1;
                    end
                end
                default: begin
                    state <= IDLE;
                    data_reg <= {1'b1, data};
                    tx <= 1'b1;
                    tx_busy <= 0;
                end
            endcase
        end
    end
endmodule

module uart_rx #(
    parameter DATA_BIT = 8
) (
    input clk,
    input rst,
    input bps,
    input rx,
    output reg rx_done,
    output [DATA_BIT-1:0] rx_data
);
    localparam IDLE = 0, DATA = 1;
    reg b_state;
    reg [DATA_BIT:0] data_buf;
    reg [4:0] counter_reg;

    // Start bit를 감지한 뒤 각 데이터 비트의 중앙에서 LSB First로 수신한다.
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            b_state <= IDLE;
            counter_reg <= 5'd8;
            data_buf <= 9'h1FF;
            rx_done <= 0;
        end else begin
            case (b_state)
                IDLE: begin
                    rx_done  <= 0;
                    data_buf <= 9'h1FF;
                    if (bps && !rx) begin
                        b_state <= DATA;
                        counter_reg <= counter_reg + 1;
                    end else begin
                        b_state <= b_state;
                        counter_reg <= counter_reg;
                    end
                end
                DATA: begin
                    if (bps) begin
                        if (counter_reg >= 5'd15) begin
                            data_buf <= {rx, data_buf[DATA_BIT:1]};
                            if (data_buf[0]) begin
                                b_state <= DATA;
                                counter_reg <= 5'd0;
                                rx_done <= 0;
                            end else begin
                                b_state <= IDLE;
                                counter_reg <= 5'd8;
                                rx_done <= 1;
                            end
                        end else begin
                            b_state <= DATA;
                            counter_reg <= counter_reg + 1;
                            rx_done <= 0;
                            data_buf <= data_buf;
                        end
                    end else begin
                        b_state <= b_state;
                        counter_reg <= counter_reg;
                        rx_done <= 0;
                        data_buf <= data_buf;
                    end
                end
                default: begin
                    b_state <= IDLE;
                    counter_reg <= 5'd8;
                    rx_done <= 0;
                    data_buf <= 9'h1FF;
                end
            endcase
        end
    end
    assign rx_data = data_buf[DATA_BIT-1:0];
endmodule

module tick_gen #(
    parameter bps_value = 9600,
    F_COUNT = 100_000_000
) (
    input clk,
    rst,
    output reg o_bps_tick
);
    // 시스템 클럭을 목표 Baud Rate의 16배 오버샘플링 Tick으로 분주한다.
    parameter b_value = F_COUNT / bps_value / 16;
    reg [$clog2(b_value)-1 : 0] count_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg  <= 0;
            o_bps_tick <= 1;
        end else begin
            if (count_reg >= b_value - 1) begin
                count_reg  <= 0;
                o_bps_tick <= 1;
            end else begin
                count_reg  <= count_reg + 1;
                o_bps_tick <= 0;
            end
        end
    end
endmodule


