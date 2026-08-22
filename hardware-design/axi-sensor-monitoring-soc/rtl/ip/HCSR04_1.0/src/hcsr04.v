`timescale 1ns / 1ps

module hcsr04 (
    input            clk,
    input            rst,
    input            start,
    input            echo,
    output reg       trig,
    output reg       SR04_DONE,
    output reg [8:0] distance
);

    wire tick_us;
    tick_gen_us U_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .tick_us(tick_us)
    );

    reg [ 1:0] state;
    reg [ 3:0] tick_counter;
    reg [14:0] trig_counter;
    localparam IDLE = 0, STAR = 1, WAIT = 2, REP = 3;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            trig <= 0;
            distance <= 0;
            trig_counter <= 0;
            tick_counter <= 0;
            state <= IDLE;
            SR04_DONE <= 0;
        end else begin
            // 트리거 출력 후 Echo High 시간을 측정해 거리 값으로 변환한다.
            case (state)
                IDLE: begin
                    distance <= distance;
                    tick_counter <= 0;
                    trig <= 0;
                    SR04_DONE <= 0;
                    if (start) begin
                        state <= STAR;
                        trig_counter <= 0;
                        trig <= 1;
                    end else begin
                        state <= IDLE;
                        trig_counter <= 0;
                        trig <= 0;
                    end
                end
                STAR: begin
                    distance <= 0;
                    trig_counter <= trig_counter + 1;
                    SR04_DONE <= 0;
                    if (tick_counter >= 12) begin
                        state <= WAIT;
                        trig <= 0;
                        tick_counter <= 0;
                    end else begin
                        state <= STAR;
                        if (tick_us) begin
                            trig <= 1;
                            tick_counter <= tick_counter + 1;
                        end else begin
                            trig <= trig;
                            tick_counter <= tick_counter;
                        end
                    end
                end
                WAIT: begin
                    tick_counter <= 0;
                    trig <= 0;
                    SR04_DONE <= 0;
                    if (echo && tick_us) begin
                        state <= REP;
                        distance <= 0;
                        trig_counter <= trig_counter + 1;
                    end else begin
                        state <= WAIT;
                        distance <= 0;
                        trig_counter <= 0;
                    end
                end
                REP: begin
                    distance <= distance;
                    trig_counter <= 0;
                    trig <= 0;
                    tick_counter <= 0;
                    if (echo == 0) begin
                        state <= IDLE;
                        SR04_DONE <= 1;
                    end else begin
                        state <= REP;
                        SR04_DONE <= 0;
                        if (tick_us) begin
                            if (trig_counter >= 58) begin
                                trig_counter <= 0;
                                distance <= distance + 1;
                            end else begin
                                trig_counter <= trig_counter + 1;
                                distance <= distance;
                            end
                        end else begin
                            trig_counter <= trig_counter;
                            distance <= distance;
                        end
                    end

                end
            endcase
        end
    end
endmodule


module tick_gen_us (
    input      clk,
    input      rst,
    output reg tick_us
);

    parameter F_COUNT = 100_000_000 / 1_000_000;
    reg [$clog2(F_COUNT) -1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_us     <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_us     <= 1'b1;
            end else begin
                tick_us <= 1'b0;
            end
        end
    end
endmodule
