`timescale 1ns / 1ps

module counter_ip (
    input  logic       clk,
    input  logic       rst,
    input  logic       start,
    input  logic [7:0] slave_in,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);

    logic [13:0] tick_counter;
    logic [ 2:0] control;

    control_unit U_CONRTOL_UNIT (
        .clk    (clk),
        .rst    (rst),
        .start  (start),
        .sw     (slave_in[2:0]),
        .runstop(runstop),
        .clear  (clear),
        .mode   (mode)
    );

    fnd_controller U_FND_CONTROLLER (
        .clk     (clk),
        .rst     (rst),
        .fnd_in  (tick_counter),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

    datapath U_DATAPATH (
        .clk         (clk),
        .clear       (clear),
        .runstop     (runstop),
        .mode        (mode),
        .tick_counter(tick_counter)
    );

endmodule

module control_unit (
    input  logic [2:0] sw,
    input  logic       clk,
    input  logic       rst,
    input  logic       start,
    output logic       runstop,
    output logic       clear,
    output logic       mode
);
    logic [13:0] tick_counter;
    logic [ 2:0] control;
    logic [2:0] slave_in_r;

    always @(posedge clk)begin
        if(rst)begin
            slave_in_r    <= 0;
            runstop        <= 0;
            mode           <= 0;
        end
        else begin
            if(start)begin
                slave_in_r[0] <= sw[0];
                slave_in_r[1] <= sw[1];
                slave_in_r[2] <= sw[2];
            end else slave_in_r <= 0;

            if(slave_in_r[0]) runstop <= ~runstop;
            if(slave_in_r[2]) mode <= ~mode;
        end
        clear = slave_in_r[1]|rst;
    end
endmodule

module datapath (
    input  logic        clk,
    input  logic        runstop,
    input  logic        clear,
    input  logic        mode,
    output logic [13:0] tick_counter
);

    logic w_tick_10hz;

    tick_counter U_TICK_COUNTER (
        .clk           (clk),
        .en            (runstop),
        .rst           (clear),
        .i_tick        (w_tick_10hz),
        .mode          (mode),
        .o_tick_counter(tick_counter)
    );

    clk_tick_gen U_CLK_TICK_GEN (
        .clk   (clk),
        .en    (runstop),
        .rst   (clear),
        .o_tick(w_tick_10hz)
    );

endmodule

module tick_counter (
    input  logic        clk,
    input  logic        en,
    input  logic        rst,
    input  logic        i_tick,
    input  logic        mode,
    output logic [13:0] o_tick_counter
);

    logic [$clog2(10_000)-1:0] tick_counter_reg;

    assign o_tick_counter = tick_counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            tick_counter_reg <= 14'd0;
        end else if (en) begin

            if (!mode) begin
                if (i_tick == 1'b1) begin
                    tick_counter_reg <= tick_counter_reg + 1;
                    if (tick_counter_reg == (10_000 - 1)) begin
                        tick_counter_reg <= 14'd0;
                    end
                end
            end else begin
                if (i_tick == 1'b1) begin
                    tick_counter_reg <= tick_counter_reg - 1;
                    if (tick_counter_reg == 14'd0) begin
                        tick_counter_reg <= 14'd9999;
                    end
                end
            end
        end
    end
endmodule

module clk_tick_gen #(
    parameter TICK_COUNT = 10_000_000
) (
    input  logic clk,
    input  logic en,
    input  logic rst,
    output logic o_tick
);


    logic [$clog2(TICK_COUNT)-1:0] counter_reg;

    // 파라미터로 지정한 클럭 수마다 한 주기의 동작 기준 펄스를 생성한다.
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_tick      <= 1'b0;
        end else if (en) begin
            counter_reg <= counter_reg + 1;
            o_tick      <= 1'b0;
            if (counter_reg == (TICK_COUNT - 1)) begin
                counter_reg <= 0;
                o_tick      <= 1'b1;
            end
        end else begin
            o_tick <= 1'b0;
        end
    end
endmodule


module fnd_controller (
    input  logic        clk,
    input  logic        rst,
    input  logic [13:0] fnd_in,
    output logic [ 3:0] fnd_com,
    output logic [ 7:0] fnd_data
);

    logic [3:0] w_out_mux;
    logic [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
    logic [1:0] w_digit_sel;
    logic       w_1KHz;

    // 4자리 값을 분리하고 1 kHz로 순환 선택해 FND를 동적 구동한다.
    digit_splitter U_DIGIT_SPLIT (
        .digit_in  (fnd_in),
        .digit_1   (w_digit_1),
        .digit_10  (w_digit_10),
        .digit_100 (w_digit_100),
        .digit_1000(w_digit_1000)
    );

    mux_4x1 U_MUX_4X1 (
        .in0    (w_digit_1),
        .in1    (w_digit_10),
        .in2    (w_digit_100),
        .in3    (w_digit_1000),
        .sel    (w_digit_sel),
        .out_mux(w_out_mux)
    );

    bcd U_BCD (
        .bin     (w_out_mux),
        .bcd_data(fnd_data)
    );

    clk_div_1KHz U_CLK_DIV_1KHZ (
        .clk(clk),
        .rst(rst),
        .o_1KHz(w_1KHz)
    );

    counter_4 U_COUNTER_4 (
        .clk      (w_1KHz),
        .rst      (rst),
        .digit_sel(w_digit_sel)
    );

    decoder2x4 U_DECODER_2X4 (
        .decoder_in(w_digit_sel),
        .fnd_com   (fnd_com)
    );

endmodule

module clk_div_1KHz #(
    parameter DIV_COUNT = 50_000
) (
    input  logic clk,
    input  logic rst,
    output logic o_1KHz
);

    logic [$clog2(DIV_COUNT)-1:0] counter_reg;
    logic o_1KHz_reg;

    assign o_1KHz = o_1KHz_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            o_1KHz_reg  <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (DIV_COUNT - 1)) begin
                counter_reg <= 0;
                o_1KHz_reg  <= ~o_1KHz_reg;
            end
        end
    end

endmodule


module counter_4 (
    input  logic       clk,
    input  logic       rst,
    output logic [1:0] digit_sel
);

    logic [1:0] counter_reg;
    assign digit_sel = counter_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_reg + 1;
        end
    end

endmodule


module decoder2x4 (
    input      [1:0] decoder_in,
    output reg [3:0] fnd_com
);

    always_comb begin
        case (decoder_in)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end


endmodule

module digit_splitter (
    input  logic [13:0] digit_in,
    output logic [ 3:0] digit_1,
    output logic [ 3:0] digit_10,
    output logic [ 3:0] digit_100,
    output logic [ 3:0] digit_1000
);

    assign digit_1 = digit_in % 10;
    assign digit_10 = (digit_in / 10) % 10;
    assign digit_100 = (digit_in / 100) % 10;
    assign digit_1000 = (digit_in / 1000) % 10;

endmodule

module mux_4x1 (

    input  logic [3:0] in0,
    input  logic [3:0] in1,
    input  logic [3:0] in2,
    input  logic [3:0] in3,
    input  logic [1:0] sel,
    output logic [3:0] out_mux

);
    logic [3:0] out_reg;
    assign out_mux = out_reg;


    always_comb begin
        case (sel)
            2'b00:   out_reg = in0;
            2'b01:   out_reg = in1;
            2'b10:   out_reg = in2;
            2'b11:   out_reg = in3;
            default: out_reg = 4'b0000;
        endcase
    end

endmodule

module bcd (
    input  logic [3:0] bin,
    output logic [7:0] bcd_data
);

    always_comb begin
        case (bin)
            4'b0000: bcd_data = 8'hC0;
            4'b0001: bcd_data = 8'hF9;
            4'b0010: bcd_data = 8'hA4;
            4'b0011: bcd_data = 8'hB0;
            4'b0100: bcd_data = 8'h99;
            4'b0101: bcd_data = 8'h92;
            4'b0110: bcd_data = 8'h82;
            4'b0111: bcd_data = 8'hF8;
            4'b1000: bcd_data = 8'h80;
            4'b1001: bcd_data = 8'h90;
            4'b1010: bcd_data = 8'h88;
            4'b1011: bcd_data = 8'h83;
            4'b1100: bcd_data = 8'hC6;
            4'b1101: bcd_data = 8'hA1;
            4'b1110: bcd_data = 8'h86;
            4'b1111: bcd_data = 8'h8E;
            default: bcd_data = 8'hFF;
        endcase
    end

endmodule
