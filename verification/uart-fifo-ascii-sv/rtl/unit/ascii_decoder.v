module ascii_decoder (
    input clk,
    input start,
    input rst,
    input [7:0] UART_DATA,
    output reg [5:0] button_sel
);
    localparam IDLE = 0, DATA = 1;
    reg state;
    reg [7:0] UART_DATA_buf;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            button_sel <= 0;
            UART_DATA_buf <= 0;
        end else begin
            case (state)
                IDLE: begin
                    button_sel <= 0;
                    UART_DATA_buf <= UART_DATA;
                    if (start) state <= DATA;
                    else state <= IDLE;
                end
                DATA: begin
                    state <= IDLE;
                    UART_DATA_buf <= UART_DATA_buf;

                    // 영문 명령의 대문자와 소문자를 동일한 버튼 신호로 변환한다.
                    case (UART_DATA_buf)
                        8'h44:   button_sel <= 6'b000001;
                        8'h4C:   button_sel <= 6'b000010;
                        8'h4D:   button_sel <= 6'b000100;
                        8'h52:   button_sel <= 6'b001000;
                        8'h53:   button_sel <= 6'b010000;
                        8'h55:   button_sel <= 6'b100000;
                        8'h64:   button_sel <= 6'b000001;
                        8'h6C:   button_sel <= 6'b000010;
                        8'h6D:   button_sel <= 6'b000100;
                        8'h72:   button_sel <= 6'b001000;
                        8'h73:   button_sel <= 6'b010000;
                        8'h75:   button_sel <= 6'b100000;
                        default: button_sel <= 0;
                    endcase
                end
                default: begin

                end
            endcase
        end
    end
endmodule
