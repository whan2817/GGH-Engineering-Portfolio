`timescale 1ns / 1ps

module watch_datapath #(
    parameter MSEC_MOD  = 100   ,
    parameter MOD_6  = 6        ,
    parameter MOD_10 = 10       ,
    parameter HOUR_MOD  = 24    ,
    parameter MSEC_WIDTH    = $clog2(MSEC_MOD)  ,
    parameter SEC1_WIDTH    = $clog2(MOD_10)  ,
    parameter SEC10_WIDTH   = $clog2(MOD_6) ,
    parameter MIN1_WIDTH    = $clog2(MOD_10)  ,
    parameter MIN10_WIDTH   = $clog2(MOD_6) ,
    parameter HOUR_WIDTH    = $clog2(HOUR_MOD))(
    input                           clk         ,
    input                           rst         ,
    input                           i_set_mode  ,
    input                           i_digit_sel,
    input  [1:0]                    i_time_sel  ,
    input  [1:0]                    i_edit_cmd  ,
    output [6:0]                    msec,
    output [5:0]                    sec ,    
    output [5:0]                    min ,
    output [4:0]                    hour        
);
    wire [SEC1_WIDTH - 1:0]       sec_d1      ;    
    wire [SEC10_WIDTH - 1:0]      sec_d10     ;    
    wire [MIN1_WIDTH - 1:0]       min_d1      ;
    wire [MIN10_WIDTH - 1:0]      min_d10     ;
    
    assign sec = sec_d1+ sec_d10*10;
    assign min = min_d1+ min_d10*10;

    wire    w_tick_100hz    ,
            w_msec_tick     , 
            w_sec1_tick     , 
            w_sec10_tick    , 
            w_min1_tick     , 
            w_min10_tick    ;
    
    reg [1:0] r_edit_sec1, r_edit_sec10, r_edit_min1, r_edit_min10, r_edit_hour;


    // 설정 모드에서 선택된 시간 단위와 자릿수에만 증가 또는 감소 명령을 전달한다.
    always @(*) begin

        r_edit_sec1  = 2'b00;
        r_edit_sec10 = 2'b00;
        r_edit_min1  = 2'b00;
        r_edit_min10 = 2'b00;
        r_edit_hour  = 2'b00;   
                
        case(i_time_sel)
            2'b00 :  begin
                r_edit_hour =  i_edit_cmd;    
            end
            2'b01 :  begin
                if(i_digit_sel) begin
                   r_edit_min1 =  i_edit_cmd;    
                end
                else begin
                    r_edit_min10 =  i_edit_cmd;
                end                
            end
            2'b10 :  begin
                if(i_digit_sel) begin
                   r_edit_sec1 =  i_edit_cmd;    
                end
                else begin
                    r_edit_sec10 =  i_edit_cmd;
                end                
            end
        endcase
    end


    // 시, 분, 초, 1/100초 카운터를 Carry 신호로 연결한다.
    tick_counter_wt #(
        .TIMES(HOUR_MOD),
        .BIT_WIDTH($clog2(HOUR_MOD))
    )uHOUR_CNT(
        .clk(clk),
        .rst(rst),
        .i_tick(w_min10_tick),
        .i_edit_cmd(r_edit_hour),
        .time_counter(hour),
        .o_tick()
    );


    tick_counter_wt #(
        .TIMES(MOD_6),
        .BIT_WIDTH($clog2(MOD_6))
    )uMIN10_CNT(
        .clk(clk),
        .rst(rst),
        .i_tick(w_min1_tick),
        .i_edit_cmd(r_edit_min10),
        .time_counter(min_d10),
        .o_tick(w_min10_tick)
    );


    tick_counter_wt #(
        .TIMES(MOD_10),
        .BIT_WIDTH($clog2(MOD_10))
    )uMIN1_CNT(
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec10_tick),
        .i_edit_cmd(r_edit_min1),
        .time_counter(min_d1),
        .o_tick(w_min1_tick)
    );


    tick_counter_wt #(
        .TIMES(MOD_6),
        .BIT_WIDTH($clog2(MOD_6))
    )uSEC10_CNT(
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec1_tick),
        .i_edit_cmd(r_edit_sec10),
        .time_counter(sec_d10),
        .o_tick(w_sec10_tick)
    );


    tick_counter_wt #(
        .TIMES(MOD_10),
        .BIT_WIDTH($clog2(MOD_10))
    )uSEC1_CNT(
        .clk(clk),
        .rst(rst),
        .i_tick(w_msec_tick),
        .i_edit_cmd(r_edit_sec1),
        .time_counter(sec_d1),
        .o_tick(w_sec1_tick)
    );


    tick_counter_wt #(
        .TIMES(MSEC_MOD),
        .BIT_WIDTH($clog2(MSEC_MOD))
    )uMSEC_CNT(
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_100hz),
        .i_edit_cmd(2'b00),
        .time_counter(msec),
        .o_tick(w_msec_tick)
    );


    tick_gen_100hz_wt uTICK_GEN_100HZ(
        .clk         (clk         ),
        .rst         (rst         ),
        .i_run_en    (~i_set_mode ), 
        .o_tick_100hz(w_tick_100hz)
    );


endmodule


module tick_counter_wt #(
    parameter TIMES = 100,
    parameter BIT_WIDTH = 7
)(
    input                           clk,
    input                           rst,
    input                           i_tick,
    input       [1:0]               i_edit_cmd,
    output      [BIT_WIDTH-1:0]     time_counter,
    output                          o_tick
);

    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign time_counter = counter_reg;
    assign o_tick = i_tick && (counter_reg == TIMES - 1);

    always @(posedge clk or posedge rst) begin
        if (rst)
            counter_reg <= 0;
        else
            counter_reg <= counter_next;
    end

    // 실행 모드에서는 Tick으로 증가하고 설정 모드에서는 편집 명령으로 값을 조정한다.
    always @(*) begin
        counter_next = counter_reg;

        if (i_tick) begin
            if (counter_reg == TIMES - 1)
                counter_next = 0;
            else
                counter_next = counter_reg + 1'b1;
        end
        else begin
            case (i_edit_cmd)
                2'b01: begin
                    if (counter_reg == TIMES - 1)
                        counter_next = 0;
                    else
                        counter_next = counter_reg + 1'b1;
                end

                2'b10: begin
                    if (counter_reg == 0)
                        counter_next = TIMES - 1;
                    else
                        counter_next = counter_reg - 1'b1;
                end

                default: begin
                    counter_next = counter_reg;
                end
            endcase
        end
    end

endmodule


// 시계 실행 모드에서만 100 Hz 시간 기준 Tick을 생성한다.
module tick_gen_100hz_wt (
    input           clk             ,
    input           rst             ,
    input           i_run_en        ,
    output reg      o_tick_100hz
);


    parameter F_COUNT = 100_000_000 / 100;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            counter_reg     <= 0;
            o_tick_100hz    <= 1'b0;
        end
        else if(i_run_en) begin
            counter_reg     <= counter_reg + 1'b1;
            o_tick_100hz    <= 1'b0;
            if(counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                o_tick_100hz      <= 1'b1;
            end 
            else begin
                o_tick_100hz      <= 1'b0;
            end                
        end 
        else begin
            counter_reg     <= counter_reg;
            o_tick_100hz    <= 1'b0;
        end
    end

endmodule

