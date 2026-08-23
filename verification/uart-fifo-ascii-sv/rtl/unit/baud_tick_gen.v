module baud_tick_gen #(
    parameter bps_value = 9600,
    F_COUNT = 100_000_000
) (
    input clk,
    rst,
    output reg o_b_tick
);
    parameter b_value = F_COUNT / bps_value / 16;
    reg [$clog2(b_value)-1 : 0] count_reg;

    // 시스템 클럭을 UART 16배 오버샘플링 주기로 분주한다.
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg <= 0;
            o_b_tick  <= 1;
        end else begin
            if (count_reg >= b_value - 1) begin
                count_reg <= 0;
                o_b_tick  <= 1;
            end else begin
                count_reg <= count_reg + 1;
                o_b_tick  <= 0;
            end
        end
    end
endmodule
