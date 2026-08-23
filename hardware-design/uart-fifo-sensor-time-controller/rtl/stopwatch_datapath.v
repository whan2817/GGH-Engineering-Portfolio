`timescale 1ns / 1ps


module stopwatch_datapath #(
    parameter MSEC_WIDTH = 7, 
              SEC_WIDTH  = 6, 
              MIN_WIDTH  = 6, 
              HOUR_WIDTH = 5)
(
    input                           clk         ,
    input                           rst         ,
    input                           i_runstop   ,
    input                           i_clear     ,
    input                           i_mode      ,   
    output [MSEC_WIDTH - 1:0]       msec        ,
    output [ SEC_WIDTH - 1:0]        sec        ,    
    output [ MIN_WIDTH - 1:0]        min        ,
    output [HOUR_WIDTH - 1:0]       hour        
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;


    // 1/100초부터 시 단위까지 Carry 신호로 연결해 누적 시간을 생성한다.
    tick_counter_st #(
        .TIMES(24), 
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_HOUR_TICK_COUNTER(
        .clk           (clk   ),
        .rst           (rst   ),
        .i_tick        (w_hour_tick),
        .i_clear       (i_clear     ),
        .i_mode        (i_mode      ),
        .time_counter  (hour  ),
        .o_tick        ()
    );

    tick_counter_st #(
        .TIMES(60), 
        .BIT_WIDTH(MIN_WIDTH)
    ) U_MIN_TICK_COUNTER(
        .clk           (clk   ),
        .rst           (rst   ),
        .i_tick        (w_min_tick),
        .i_clear       (i_clear     ),
        .i_mode        (i_mode      ),
        .time_counter  (min  ),
        .o_tick        (w_hour_tick)
    );

    tick_counter_st #(
        .TIMES(60), 
        .BIT_WIDTH(SEC_WIDTH)
    ) U_SEC_TICK_COUNTER(
        .clk           (clk   ),
        .rst           (rst   ),
        .i_tick        (w_sec_tick),
        .i_clear       (i_clear     ),
        .i_mode        (i_mode      ),    
        .time_counter  (sec  ),
        .o_tick        (w_min_tick)
    );

    tick_counter_st #(
        .TIMES(100), 
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_MSEC_TICK_COUNTER(
        .clk           (clk   ),
        .rst           (rst   ),
        .i_tick        (w_tick_100hz),
        .i_clear       (i_clear     ),
        .i_mode        (i_mode      ),
        .time_counter  (msec  ),
        .o_tick        (w_sec_tick)
    );

    tick_gen_100hz_st U_TICK_GEN_100HZ(
        .clk         (clk         ),
        .rst         (rst         ),
        .i_runstop   (i_runstop   ),
        .i_clear     (i_clear     ),  
        .o_tick_100hz(w_tick_100hz)
    );


endmodule


module tick_counter_st #(
    parameter TIMES = 100, BIT_WIDTH = 7)(
    input                             clk           ,
    input                             rst           ,
    input                             i_tick        ,
    input                             i_clear       ,
    input                             i_mode        ,
    output      [BIT_WIDTH -1 : 0]    time_counter  ,
    output reg                        o_tick
);

    reg [BIT_WIDTH - 1 : 0] counter_reg, counter_next;


    assign time_counter = counter_reg;

    always@(posedge clk, posedge rst)begin
        if(rst) begin
            counter_reg <= 0;

        end
        else begin
            counter_reg <= counter_next;

        end
    end


    // 모드에 따라 증가 또는 감소하고 각 단위의 경계에서 다음 카운터로 Carry를 전달한다.
    always@(*) begin
        counter_next = counter_reg;
        o_tick    = 1'b0;   
        if(i_tick) begin

           if(i_mode) begin
                counter_next = counter_next - 1'b1;
                o_tick    = 1'b0; 
                if(counter_reg == 0) begin
                   counter_next = TIMES - 1;
                   o_tick    = 1'b1;  
                end             
           end
           else begin
                counter_next = counter_next + 1'b1;
                o_tick    = 1'b0; 
                if(counter_reg == TIMES - 1) begin
                   counter_next = 1'b0;
                   o_tick    = 1'b1;  
           end             
           end  
        end
        else if(i_clear) begin
            counter_next = 0;
            o_tick       = 1'b0;
                  
        end
    end

    
endmodule


// Run 상태에서만 100 Hz Tick을 생성하며 Clear 입력 시 분주 카운터도 초기화한다.
module tick_gen_100hz_st (
    input           clk         ,
    input           rst         ,
    input           i_runstop   ,
    input           i_clear  ,
    output reg      o_tick_100hz
);


    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg   <= 0;
            o_tick_100hz  <= 1'b0;
        end
        else if (i_clear) begin
            counter_reg   <= 0;
            o_tick_100hz  <= 1'b0;
        end
        else if (i_runstop) begin
            counter_reg   <= counter_reg + 1'b1;
            o_tick_100hz  <= 1'b0;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg  <= 0;
                o_tick_100hz <= 1'b1;
            end
        end
        else begin
            counter_reg   <= counter_reg;
            o_tick_100hz  <= 1'b0;
        end
    end
endmodule


