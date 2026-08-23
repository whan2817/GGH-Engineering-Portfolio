
module sender #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input clk,
    input rst,
    input [1:0] sw,
    input status,
    input [31:0] in_data,
    output run,
    output [7:0] out_data
);
    wire [3:0] w_msec_digit_1, w_msec_digit_10;
    wire [3:0] w_sec_digit_1, w_sec_digit_10;
    wire [3:0] w_min_digit_1, w_min_digit_10;
    wire [3:0] w_hour_digit_1, w_hour_digit_10;

    // 선택된 32 bit 데이터를 시간과 센서 출력에 사용할 십진 자릿수로 분리한다.
    digit_splitter #(
        .BIT_WIDTH(8)
    ) U_MSEC_DS (
        .digit_in(in_data[7:0]),
        .digit_1 (w_msec_digit_1),
        .digit_10(w_msec_digit_10)
    );
    digit_splitter #(
        .BIT_WIDTH(8)
    ) U_SEC_DS (
        .digit_in(in_data[15:8]),
        .digit_1 (w_sec_digit_1),
        .digit_10(w_sec_digit_10)
    );
    digit_splitter #(
        .BIT_WIDTH(8)
    ) U_MIN_DS (
        .digit_in(in_data[23:16]),
        .digit_1 (w_min_digit_1),
        .digit_10(w_min_digit_10)
    );
    digit_splitter #(
        .BIT_WIDTH(8)
    ) U_HOUR_DS (
        .digit_in(in_data[31:24]),
        .digit_1 (w_hour_digit_1),
        .digit_10(w_hour_digit_10)
    );

    wire [4:0] digit_c0, digit_c4, digit_c2, digit_c6;
    wire [4:0] digit_c1, digit_c5, digit_c3, digit_c7;
    wire [4:0] trans_to_ascii;
    wire [3:0] mux16_sel;

    // 현재 모드에 맞는 고정 문자열과 구분 문자를 선택한다.
    assign digit_c0=(sw==2'd0)? 5'd19 :(sw==2'd1)? 5'd16:(sw==2'd2)? 5'd20:5'd22;
    assign digit_c1=(sw==2'd0)? 5'd13 :(sw==2'd1)? 5'd17:(sw==2'd2)? 5'd18:5'd20;
    assign digit_c2=(sw==2'd0)? 5'd14 :(sw==2'd1)? 5'd13:(sw==2'd2)? 5'd19:5'd13;
    assign digit_c3=(sw==2'd0)? 5'd15 :(sw==2'd1)? 5'd18:(sw==2'd2)? 5'd21:5'd26;
    assign digit_c4=(sw==2'd0)? 5'd16 :(sw==2'd1)? 5'd20:(sw==2'd2)? 5'd25:5'd25;

    assign digit_c5=(sw==2'd0||sw==2'd1)? 5'd10:(sw==2'd2)? 5'd0:5'd24;
    assign digit_c6=(sw==2'd0||sw==2'd1)? 5'd11:(sw==2'd2)? 5'd0:5'd26;
    assign digit_c7=(sw==2'd0||sw==2'd1)? 5'd12:(sw==2'd2)? 5'd27:5'd24;

    // Status 입력 시 16개 문자를 순서대로 선택해 UART 송신 데이터로 변환한다.
    counter_16 u_counter_16 (
        .clk(clk),
        .rst(rst),
        .status(status),
        .run(run),
        .digit_sel(mux16_sel)
    );
    mux_16x1 u_mux16x1 (
        .in0(digit_c0),
        .in1(digit_c1),
        .in2(digit_c2),
        .in3(digit_c3),
        .in4(digit_c4),

        .in5({1'b0, w_hour_digit_10}),
        .in6({1'b0, w_hour_digit_1}),
        .in7({1'b0, w_min_digit_10}),
        .in8({1'b0, w_min_digit_1}),
        .in9({1'b0, w_sec_digit_10}),
        .in10({1'b0, w_sec_digit_1}),
        .in11({1'b0, w_msec_digit_10}),
        .in12({1'b0, w_msec_digit_1}),
        .in13(digit_c5),
        .in14(digit_c6),
        .in15(digit_c7),
        .sel(mux16_sel),
        .out_mux(trans_to_ascii)
    );
    sender_decoder_ascii u_sender_decoder_ascii (
        .decoder_in(trans_to_ascii),
        .ascii_out (out_data)
    );
endmodule

module mux_16x1 (
    input  [4:0] in0,
    input  [4:0] in1,
    input  [4:0] in2,
    input  [4:0] in3,
    input  [4:0] in4,
    input  [4:0] in5,
    input  [4:0] in6,
    input  [4:0] in7,
    input  [4:0] in8,
    input  [4:0] in9,
    input  [4:0] in10,
    input  [4:0] in11,
    input  [4:0] in12,
    input  [4:0] in13,
    input  [4:0] in14,
    input  [4:0] in15,
    input  [3:0] sel,
    output [4:0] out_mux
);
    reg [4:0] out_reg;
    assign out_mux = out_reg;

    always @(*) begin
        case (sel)
            4'b0000: out_reg = in0;
            4'b0001: out_reg = in1;
            4'b0010: out_reg = in2;
            4'b0011: out_reg = in3;
            4'b0100: out_reg = in4;
            4'b0101: out_reg = in5;
            4'b0110: out_reg = in6;
            4'b0111: out_reg = in13;
            4'b1000: out_reg = in7;
            4'b1001: out_reg = in8;
            4'b1010: out_reg = in14;
            4'b1011: out_reg = in9;
            4'b1100: out_reg = in10;
            4'b1101: out_reg = in15;
            4'b1110: out_reg = in11;
            4'b1111: out_reg = in12;
            default: out_reg = 4'b0000;
        endcase
    end
endmodule

// 내부 문자 번호와 숫자 자릿수를 8 bit ASCII 코드로 변환한다.
module sender_decoder_ascii (
    input [4:0] decoder_in,
    output reg [7:0] ascii_out
);
    always @(*) begin
        case (decoder_in)
            5'd0:    ascii_out = 8'h30;
            5'd1:    ascii_out = 8'h31;
            5'd2:    ascii_out = 8'h32;
            5'd3:    ascii_out = 8'h33;
            5'd4:    ascii_out = 8'h34;
            5'd5:    ascii_out = 8'h35;
            5'd6:    ascii_out = 8'h36;
            5'd7:    ascii_out = 8'h37;
            5'd8:    ascii_out = 8'h38;
            5'd9:    ascii_out = 8'h39;
            5'd10:   ascii_out = 8'h68;
            5'd11:   ascii_out = 8'h6D;
            5'd12:   ascii_out = 8'h73;
            5'd13:   ascii_out = 8'h54;
            5'd14:   ascii_out = 8'h4F;
            5'd15:   ascii_out = 8'h50;
            5'd16:   ascii_out = 8'h57;
            5'd17:   ascii_out = 8'h41;
            5'd18:   ascii_out = 8'h43;
            5'd19:   ascii_out = 8'h53;
            5'd20:   ascii_out = 8'h48;
            5'd21:   ascii_out = 8'h52;
            5'd22:   ascii_out = 8'h44;
            5'd23:   ascii_out = 8'h5F;
            5'd24:   ascii_out = 8'h2E;
            5'd25:   ascii_out = 8'h7C;
            5'd26:   ascii_out = 8'h20;
            5'd27:   ascii_out = 8'h4D;
            default: ascii_out = 8'b11111111;
        endcase
    end
endmodule

module counter_16 (
    input            clk,
    input            rst,
    input            status,
    output reg       run,
    output reg [3:0] digit_sel
);
    localparam IDLE = 0, DATA = 1;
    reg state;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            digit_sel <= 4'b0000;
            run <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (status) begin
                        digit_sel <= digit_sel;
                        run <= 1;
                        state <= DATA;
                    end else begin
                        run   <= 0;
                        state <= IDLE;
                    end
                end
                DATA: begin
                    if (digit_sel >= 15) begin
                        run <= 0;
                        state <= IDLE;
                        digit_sel <= 0;
                    end else begin
                        run <= 1;
                        state <= DATA;
                        digit_sel <= digit_sel + 1;
                    end
                end
                default: begin
                    run <= 0;
                    state <= IDLE;
                    digit_sel <= digit_sel;
                end
            endcase
        end
    end

endmodule
