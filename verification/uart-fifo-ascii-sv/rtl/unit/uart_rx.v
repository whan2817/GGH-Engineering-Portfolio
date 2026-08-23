module uart_rx #(
    parameter DATA_BIT = 8
) (
    input clk,
    input rst,
    input b_tick,
    input rx,
    output reg rx_done,
    output [DATA_BIT-1:0] rx_data
);
    localparam IDLE = 0, DATA = 1;
    reg b_state;
    reg [DATA_BIT:0] data_buf;
    reg [4:0] counter_reg;

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
                    if (b_tick && !rx) begin
                        b_state <= DATA;
                        counter_reg <= counter_reg + 1;
                    end else begin
                        b_state <= b_state;
                        counter_reg <= counter_reg;
                    end
                end
                DATA: begin
                    if (b_tick) begin
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
