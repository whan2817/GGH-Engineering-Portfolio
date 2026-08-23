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

module dht11_datapath (
    input        clk,
    input        rst,
    input        dht11_start,
    input        tick_us,
    output [7:0] humidity_int,
    output [7:0] humidity_dec,
    output [7:0] temperature_int,
    output [7:0] temperature_dec,
    output       valid,
    inout        dht11
);

    parameter IDLE = 0, START = 1, WAIT = 2, SYNCL = 3, SYNCH = 4;
    parameter DATA_SYNC = 5, DATA_COUNT = 6, DATA_DECISION = 7;
    parameter STOP = 8;


    reg [3:0] c_state, n_state;
    reg [5:0] bit_cnt_reg, bit_cnt_next;
    reg [$clog2(19_500):0] tick_cnt_reg, tick_cnt_next;
    reg out_sel_reg, out_sel_next;
    reg dht11_reg, dht11_next;

    reg [39:0] data_reg, data_next;


    // 통신 시작 구간에는 FPGA가 DATA 선을 구동하고 수신 구간에는 High-Z로 전환한다.
    assign dht11 = (out_sel_reg) ? dht11_reg : 1'bz;

    // 수신한 4 Byte의 합과 Checksum을 비교해 데이터 유효 여부를 판단한다.
    assign valid = ((data_reg[7:0]) == (data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8])) ? 1:0;

    assign humidity_int    = data_reg[39:32];
    assign humidity_dec    = data_reg[31:24];
    assign temperature_int = data_reg[23:16];
    assign temperature_dec = data_reg[15:8];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            bit_cnt_reg  <= 0;
            tick_cnt_reg <= 0;
            out_sel_reg  <= 1'b1;
            dht11_reg    <= 1'b1;
            data_reg     <= 1;
        end else begin
            c_state      <= n_state;
            bit_cnt_reg  <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            out_sel_reg  <= out_sel_next;
            dht11_reg    <= dht11_next;
            data_reg     <= data_next;
        end
    end

    // DHT11 응답 시간과 각 비트의 High 유지 시간을 기준으로 40 bit 데이터를 복원한다.
    always @(*) begin
        n_state       = c_state;
        bit_cnt_next  = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        out_sel_next  = out_sel_reg;
        dht11_next    = dht11_reg;
        data_next     = data_reg;
        case (c_state)
            IDLE: begin
                dht11_next   = 1'b1;
                out_sel_next = 1'b1;
                if (dht11_start) begin
                    bit_cnt_next  = 0;
                    tick_cnt_next = 0;
                    n_state       = START;
                    dht11_next    = 1'b0;
                end
            end
            START: begin
                dht11_next = 1'b0;
                if (tick_us) begin
                    if (tick_cnt_reg > 19_000) begin
                        tick_cnt_next = 0;
                        n_state       = WAIT;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                dht11_next = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg > 30) begin
                        tick_cnt_next = 0;
                        n_state       = SYNCL;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            SYNCL: begin

                out_sel_next = 1'b0;
                if (tick_us) begin
                    if ((tick_cnt_reg > 40) && (dht11)) begin
                        tick_cnt_next = 0;
                        n_state = SYNCH;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            SYNCH: begin
                if (tick_us) begin
                    if ((tick_cnt_reg > 40) && (!dht11)) begin
                        tick_cnt_next = 0;
                        n_state = DATA_SYNC;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            DATA_SYNC: begin
                if (tick_us) begin
                    if (dht11) begin
                        tick_cnt_next = 0;
                        n_state = DATA_COUNT;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            DATA_COUNT: begin
                if (tick_us) begin
                    if (!dht11) begin
                        n_state = DATA_DECISION;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
            DATA_DECISION: begin
                if (tick_us) begin
                    // High 구간이 임계 시간보다 길면 1, 짧으면 0으로 판별한다.
                    if (tick_cnt_reg > 45) begin
                        data_next[39-(bit_cnt_reg)] = 1'b1;
                        bit_cnt_next = bit_cnt_reg + 1;
                        tick_cnt_next = 0;
                        if (bit_cnt_reg == 39) begin
                            n_state = STOP;
                            tick_cnt_next = 0;
                        end else begin
                            n_state = DATA_SYNC;
                        end
                    end else begin
                        data_next[39-(bit_cnt_reg)] = 1'b0;
                        bit_cnt_next = bit_cnt_reg + 1;
                        tick_cnt_next = 0;
                        if (bit_cnt_reg == 39) begin
                            n_state = STOP;
                            tick_cnt_next = 0;
                        end else begin
                            n_state = DATA_SYNC;
                        end
                    end
                end
            end
            STOP: begin
                if (tick_us) begin
                    if (tick_cnt_reg > 50) begin
                        tick_cnt_next = 0;
                        n_state = IDLE;
                    end else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule

module sr04_datapath (
    input clk,
    input rst,
    input btnR,
    input echo,
    input tick_us,
    output reg trig,
    output reg SR04_DONE,
    output reg [8:0] distance
);
    reg [ 1:0] state;
    reg [ 3:0] tick_counter;
    reg [14:0] trig_counter;
    localparam IDLE = 0, STAR = 1, WAIT = 2, REP = 3;
    // Trigger를 출력한 뒤 Echo High 시간을 58 us 단위로 누적해 거리를 계산한다.
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            trig <= 0;
            distance <= 0;
            trig_counter <= 0;
            tick_counter <= 0;
            state <= IDLE;
            SR04_DONE <= 0;
        end else begin
            case (state)
                IDLE: begin
                    distance <= distance;
                    tick_counter <= 0;
                    trig <= 0;
                    SR04_DONE <= 0;
                    if (btnR) begin
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

