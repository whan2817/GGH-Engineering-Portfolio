`timescale 1ns / 1ps

module control (
    input clk,
    input rst,
    input btnR,
    btnL,
    btnU,
    btnD,
    input [2:0] sw,

    output o_mode,
    output reg o_clear,
    output reg o_runstop,
    output reg o_set_mode,
    output reg [1:0] o_timesel,
    output reg o_digitsel,
    output reg [1:0] o_edit,

    output reg o_sr04_start,
    output reg o_dht11_start,

    output [7:0] led
);

    // Stopwatch, Watch, HC-SR04, DHT11 모드와 세부 동작을 하나의 FSM으로 관리한다.
    localparam SW_STOP     = 5'b00001;
    localparam SW_RUN      = 5'b00010;
    localparam SW_CLEAR    = 5'b00011;
    localparam SW_MODE     = 5'b00100;
    localparam W_RUN       = 5'b00101;
    localparam W_SET_S1    = 5'b00110;
    localparam W_SET_S10   = 5'b00111;
    localparam W_SET_M1    = 5'b01000;
    localparam W_SET_M10   = 5'b01001;
    localparam W_SET_HOUR  = 5'b01010;
    localparam SR04_STOP   = 5'b01011;
    localparam SR04_RUN_1  = 5'b01100;
    localparam SR04_RUN_2  = 5'b01101;
    localparam DHT11_STOP  = 5'b01110;
    localparam DHT11_RUN = 5'b01111;


    reg [4:0] current_state, next_state;
    reg mode_reg;
    assign o_mode = mode_reg;

    // 현재 상태를 갱신하고 Stopwatch의 증가 및 감소 방향을 전환한다.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= SW_STOP;
            mode_reg <= 1'b0;
        end else begin
            current_state <= next_state;
            if (current_state == SW_MODE) mode_reg <= ~mode_reg;
        end
    end

    // 스위치로 기능 모드를 선택하고 버튼 입력으로 각 모드의 상태를 전환한다.
    always @(*) begin
        next_state = current_state;
        case (current_state)

            SW_STOP: begin
                if (sw[2:1] == 2'b01) next_state = W_RUN;
                else if (sw[2:1] == 2'b10) next_state = SR04_STOP;
                else if (sw[2:1] == 2'b11) next_state = DHT11_STOP;
                else if (btnR) next_state = SW_RUN;
                else if (btnL) next_state = SW_CLEAR;
                else if (btnD) next_state = SW_MODE;
            end

            SW_RUN: begin
                if (sw[2:1] == 2'b01) next_state = W_RUN;
                else if (sw[2:1] == 2'b10) next_state = SR04_STOP;
                else if (sw[2:1] == 2'b11) next_state = DHT11_STOP;
                else if (btnR) next_state = SW_STOP;
            end

            SW_CLEAR, SW_MODE: begin
                next_state = SW_STOP;
            end

            W_RUN: begin
                if (sw[2:1] == 2'b00) next_state = SW_STOP;
                else if (sw[2:1] == 2'b10) next_state = SR04_STOP;
                else if (sw[2:1] == 2'b11) next_state = DHT11_STOP;
                else if (sw[0]) next_state = W_SET_S1;
            end

            W_SET_S1: begin
                if (sw[2:1] != 2'b01) next_state = SW_STOP;
                else if (!sw[0]) next_state = W_RUN;
                else if (btnL) next_state = W_SET_S10;
                else if (btnR) next_state = W_SET_HOUR;
            end

            W_SET_S10: begin
                if (sw[2:1] != 2'b01) next_state = SW_STOP;
                else if (!sw[0]) next_state = W_RUN;
                else if (btnL) next_state = W_SET_M1;
                else if (btnR) next_state = W_SET_S1;
            end

            W_SET_M1: begin
                if (sw[2:1] != 2'b01) next_state = SW_STOP;
                else if (!sw[0]) next_state = W_RUN;
                else if (btnL) next_state = W_SET_M10;
                else if (btnR) next_state = W_SET_S10;
            end

            W_SET_M10: begin
                if (sw[2:1] != 2'b01) next_state = SW_STOP;
                else if (!sw[0]) next_state = W_RUN;
                else if (btnL) next_state = W_SET_HOUR;
                else if (btnR) next_state = W_SET_M1;
            end

            W_SET_HOUR: begin
                if (sw[2:1] != 2'b01) next_state = SW_STOP;
                else if (!sw[0]) next_state = W_RUN;
                else if (btnL) next_state = W_SET_S1;
                else if (btnR) next_state = W_SET_M10;
            end

            SR04_STOP: begin
                if (sw[2:1] == 2'b00) next_state = SW_STOP;
                else if (sw[2:1] == 2'b01) next_state = W_RUN;
                else if (sw[2:1] == 2'b11) next_state = DHT11_STOP;
                else if (btnR) next_state = SR04_RUN_1;
            end

            SR04_RUN_1: begin
                next_state = SR04_RUN_2;
            end
            SR04_RUN_2: begin
                next_state = SR04_STOP;
            end

            DHT11_STOP: begin
                if (sw[2:1] == 2'b00) next_state = SW_STOP;
                else if (sw[2:1] == 2'b01) next_state = W_RUN;
                else if (sw[2:1] == 2'b10) next_state = SR04_STOP;
                else if (btnR) next_state = DHT11_RUN;
            end

            DHT11_RUN: begin
                next_state = DHT11_STOP;
            end

            default: begin
                next_state = SW_STOP;
            end

        endcase
    end

    // 현재 상태에 필요한 Datapath 제어 신호만 활성화한다.
    always @(*) begin
        o_runstop     = 1'b0;
        o_clear       = 1'b0;
        o_set_mode    = 1'b0;
        o_timesel     = 2'b00;
        o_digitsel    = 1'b0;
        o_edit        = 2'b00;
        o_sr04_start  = 1'b0;
        o_dht11_start = 1'b0;

        case (current_state)

            SW_RUN: begin
                o_runstop = 1'b1;
            end
            SW_CLEAR: begin
                o_clear = 1'b1;
            end
            W_SET_S1: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b10;
                o_digitsel = 1'b1;
                if (btnU) o_edit = 2'b01;
                else if (btnD) o_edit = 2'b10;
            end

            W_SET_S10: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b10;
                o_digitsel = 1'b0;
                if (btnU) o_edit = 2'b01;
                else if (btnD) o_edit = 2'b10;
            end
            W_SET_M1: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b01;
                o_digitsel = 1'b1;
                if (btnU) o_edit = 2'b01;
                else if (btnD) o_edit = 2'b10;
            end
            W_SET_M10: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b01;
                o_digitsel = 1'b0;
                if (btnU) o_edit = 2'b01;
                else if (btnD) o_edit = 2'b10;
            end
            W_SET_HOUR: begin
                o_set_mode = 1'b1;
                o_timesel  = 2'b00;
                o_digitsel = 1'b0;
                if (btnU) o_edit = 2'b01;
                else if (btnD) o_edit = 2'b10;
            end
            SR04_RUN_1: begin
                o_sr04_start = 1'b1;
            end
            SR04_RUN_2: begin
                o_sr04_start = 1'b1;
            end
            DHT11_RUN: begin
                o_dht11_start = 1'b1;
            end
        endcase
    end

    // LED에 현재 기능 모드와 Watch 설정 위치를 표시한다.
    assign led[0] = (current_state == SW_STOP || current_state == SW_RUN);
    assign led[1] = (current_state == W_RUN);
    assign led[2] = (current_state == SR04_STOP);
    assign led[3] = ((current_state == DHT11_STOP) || (current_state == DHT11_RUN));
    assign led[4] = (current_state == W_SET_M1);
    assign led[5] = (current_state == W_SET_M10);
    assign led[6] = (current_state == W_SET_S1 || current_state == W_SET_HOUR);
    assign led[7] = (current_state == W_SET_S10);

endmodule
