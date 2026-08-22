module dht11_controller (
    input           clk,
    input           rst,
    input           dht11_start,
    input           tick_us,
    output [7:0]    humidity,
    output [7:0]    temperature,
    output          valid,  
    inout           dht11
);

    
    parameter IDLE = 0, START = 1, WAIT = 2, SYNCL = 3, SYNCH = 4, 
    DATA_SYNC = 5, DATA_COUNT = 6, DATA_DECISION = 7, STOP = 8;

    reg [3:0] c_state, n_state;
    reg [5:0] bit_cnt_reg, bit_cnt_next;  
    reg [$clog2(19_000)-1:0] tick_cnt_reg, tick_cnt_next;  

    reg out_sel_reg, out_sel_next;  
    reg dht11_reg, dht11_next;  

    
    reg [39:0] data_reg, data_next;
    reg data_decision_reg, data_decision_next;

    
    assign dht11 = (out_sel_reg) ? dht11_reg : 1'bz;
    
    
    assign humidity = data_reg[39:32];
    assign temperature = data_reg[23:16];

    
    reg dht11_sync1, dht11_sync2; 

    // 비동기 센서 입력을 두 단계 플립플롭으로 동기화한다.
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            dht11_sync1 <= 1'b1;
            dht11_sync2 <= 1'b1;
        end else begin
            dht11_sync1 <= dht11;       
            dht11_sync2 <= dht11_sync1; 
        end
    end

    
    assign valid = (data_reg [7:0] == (data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg [15:8])) ? 1 : 0;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            bit_cnt_reg <= 0;
            tick_cnt_reg <= 0;
            out_sel_reg <= 1;   
            dht11_reg <= 1;     
            data_reg <= 1;
            data_decision_reg <= 0;
        end else begin
            c_state <= n_state;
            bit_cnt_reg <= bit_cnt_next;
            tick_cnt_reg <= tick_cnt_next;
            out_sel_reg <= out_sel_next;
            dht11_reg <= dht11_next;
            data_reg <= data_next;
            data_decision_reg <= data_decision_next;
        end
    end

    always @(*) begin

        n_state       = c_state;
        bit_cnt_next  = bit_cnt_reg;
        tick_cnt_next = tick_cnt_reg;
        out_sel_next  = out_sel_reg;
        dht11_next    = dht11_reg;
        data_next = data_reg;
        data_decision_next = data_decision_reg;

        // 시작 신호, 응답 동기화, 40비트 수신 순서를 상태기로 처리한다.
        case (c_state)
            IDLE: begin
                dht11_next = 1'b1;
                out_sel_next = 1'b1;
                if (dht11_start) begin
                    bit_cnt_next = 0;
                    tick_cnt_next = 0;
                    n_state = START;
                end
            end

            START: begin
                dht11_next = 1'b0;
                if (tick_us) begin
                    if (tick_cnt_reg > 19_000) begin    
                        n_state = WAIT;
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            WAIT: begin
                dht11_next = 1'b1;
                if (tick_us) begin
                    if (tick_cnt_reg > 30) begin    
                        n_state = SYNCL;
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            SYNCL: begin
                
                out_sel_next = 1'b0; 
                if (tick_us) begin
                    if ((tick_cnt_reg > 40) && (dht11_sync2)) begin
                        n_state = SYNCH;
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            SYNCH: begin
                
                    if ( (!dht11_sync2)) begin
                        n_state = DATA_SYNC;
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            

            DATA_SYNC: begin
                if (tick_us) begin
                    if (dht11_sync2) begin
                        n_state = DATA_COUNT;
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            DATA_COUNT: begin
                if (tick_us) begin
                    if (!dht11_sync2) begin
                        n_state = DATA_DECISION;
                        
                        if (tick_cnt_reg >= 45) begin
                            data_decision_next = 1'b1;
                        end
                        else begin
                            data_decision_next = 1'b0;
                        end
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

            DATA_DECISION: begin 
                bit_cnt_next = bit_cnt_reg + 1;
                
                data_next = {data_reg, data_decision_reg};
                if (bit_cnt_reg == 39) begin
                    n_state = STOP;
                    bit_cnt_next = 0;
                end
                else begin
                    n_state = DATA_SYNC;
                end
                data_decision_next = 0;
            end

            STOP: begin
                if (tick_us) begin
                    if (tick_cnt_reg > 50) begin
                        n_state = IDLE;
                        
                        tick_cnt_next = 0;
                    end
                    else begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end
                end
            end

        endcase
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
