module uart_tx #(
    parameter DATA_BIT = 8
) (
    input clk,
    input ib_tick,
    input rst,
    input tx_start,
    input [DATA_BIT-1:0] tx_data,
    output reg tx,
    output reg tx_busy
);
    localparam IDLE = 0, START = 1, S0 = 2;
    reg [1:0] state;
    reg [DATA_BIT:0] data_reg;
    reg [3:0] bps_count;
    reg bps_tick;

    always @(*) begin
        if (ib_tick) begin
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
            if (ib_tick) begin
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

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx <= 1;
            data_reg <= {1'b1, tx_data};
            tx_busy <= 0;
        end else begin
            case (state)
                IDLE: begin
                    data_reg <= {1'b0, tx_data};
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
                            data_reg <= {1'b1, tx_data};
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
                    data_reg <= {1'b1, tx_data};
                    tx <= 1'b1;
                    tx_busy <= 0;
                end
            endcase
        end
    end
endmodule
