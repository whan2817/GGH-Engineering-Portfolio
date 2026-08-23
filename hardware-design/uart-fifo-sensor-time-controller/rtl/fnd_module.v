module fnd_controller #( parameter DIV_COUNT = 50_000)
(
    input               clk     ,
    input               rst     ,
    input   [31:0]      data    ,
    input               sw      ,
    output  [3:0]       fnd_com ,
    output  [7:0]       fnd_data
);
    wire    [7:0]   split0, split1,split2, split3;
    wire    [3:0]   w_out_mux_msec_sec,w_out_mux_min_hour;
    wire    [3:0]   w_out_mux,w_dot0,w_dot1;
    wire    [3:0]   w_msec_digit_1, w_msec_digit_10;
    wire    [3:0]   w_sec_digit_1, w_sec_digit_10;   
    wire    [3:0]   w_min_digit_1, w_min_digit_10;
    wire    [3:0]   w_hour_digit_1, w_hour_digit_10;  

    wire    [2:0]   w_digit_sel;
    wire            w_1khz;
    wire            dot;
    // 32 bit 입력을 시간 또는 센서 데이터의 네 구간으로 분리한다.
    assign split0 = data[7:0];
    assign split1 = data[15:8];
    assign split2 = data[23:16];
    assign split3 = data[31:24];


    digit_splitter #( .BIT_WIDTH (8)
    )U_split_0( .digit_in(split0), .digit_1 (w_msec_digit_1), .digit_10(w_msec_digit_10));
    digit_splitter #( .BIT_WIDTH (8)
    )U_split_1( .digit_in(split1), .digit_1 (w_sec_digit_1), .digit_10(w_sec_digit_10));
    digit_splitter #( .BIT_WIDTH (8)
    )U_split_2( .digit_in(split2), .digit_1 (w_min_digit_1), .digit_10(w_min_digit_10));
    digit_splitter #( .BIT_WIDTH (8)
    )U_split_3( .digit_in(split3), .digit_1 (w_hour_digit_1), .digit_10(w_hour_digit_10));

    assign w_dot0 = 4'hF;
    assign w_dot1 = {3'b111,dot};

    // 고속 자리 선택 신호로 각 자릿수를 순환 표시해 하나의 화면처럼 보이게 한다.
    mux_8x1 uMux_MSEC_SEC(
        .in0    (w_msec_digit_1),
        .in1    (w_msec_digit_10),
        .in2    (w_sec_digit_1),
        .in3    (w_sec_digit_10),
        .in4    (w_dot0),
        .in5    (w_dot0),
        .in6    (w_dot1),
        .in7    (w_dot0),
        .sel    (w_digit_sel),
        .out_mux(w_out_mux_msec_sec)
    );

    mux_8x1 uMux_MIN_HOUR(
        .in0    (w_min_digit_1),
        .in1    (w_min_digit_10),
        .in2    (w_hour_digit_1),
        .in3    (w_hour_digit_10),
        .in4    (w_dot0),
        .in5    (w_dot0),
        .in6    (w_dot1),
        .in7    (w_dot0),
        .sel    (w_digit_sel),
        .out_mux(w_out_mux_min_hour)
    );
    
    mux_2x1 uMux_2x1(
        .in0    (w_out_mux_msec_sec)   ,
        .in1    (w_out_mux_min_hour)   ,
        .sel    (sw)   ,
        .out_mux(w_out_mux)
    );

    clk_div_1khz #(.DIV_COUNT(DIV_COUNT)
    ) uClk_div_1kHz (.clk(clk),.rst(rst),.o_1khz (w_1khz));

    bcd         uBcd0    (.bin(w_out_mux),.bcd_data (fnd_data));
    counter_8   uCNT8    (.clk(w_1khz),.rst(rst),.digit_sel (w_digit_sel));
    decoder_2x4 uDec2x4  (.decoder_in(w_digit_sel[1:0]),.fnd_com(fnd_com));
    comparator  uCOMP_dot(.comp_in  (split0[6:0]), .dot_onoff(dot));
endmodule

module mux_2x1(
    input   [3:0]     in0       ,
    input   [3:0]     in1       ,
    input             sel       ,
    output  [3:0]     out_mux
);  assign out_mux = (sel) ? in1 : in0;
endmodule

module digit_splitter #( parameter BIT_WIDTH = 7)(
    input   [BIT_WIDTH - 1:0]   digit_in,
    output  [            3:0]   digit_1,
    output  [            3:0]   digit_10
);
    assign digit_1      = digit_in % 10;
    assign digit_10     = (digit_in / 10) % 10;
endmodule

module mux_8x1 (
    input       [3:0]   in0,
    input       [3:0]   in1,
    input       [3:0]   in2,
    input       [3:0]   in3,
    input       [3:0]   in4,
    input       [3:0]   in5,
    input       [3:0]   in6,
    input       [3:0]   in7,
    input       [2:0]   sel,
    output      [3:0]   out_mux
);
    reg [3:0]   out_reg;
    assign out_mux = out_reg;


    always @(*) begin
        case(sel)
            3'b000   : out_reg = in0;
            3'b001   : out_reg = in1;
            3'b010   : out_reg = in2;            
            3'b011   : out_reg = in3;
            3'b100   : out_reg = in4;
            3'b101   : out_reg = in5;
            3'b110   : out_reg = in6;
            3'b111   : out_reg = in7;
            default : out_reg = 4'b0000;
        endcase        
    end
endmodule

// 선택된 숫자와 구분 기호를 FND Segment 패턴으로 변환한다.
module bcd(
    input       [3:0]       bin     ,
    output  reg [7:0]       bcd_data
);
    always@(bin) begin
        case(bin)
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
            4'b1110: bcd_data = 8'h7F;
            4'b1111: bcd_data = 8'hFF;
            default: bcd_data = 8'hFF;
        endcase
    end
endmodule


module clk_div_1khz #( parameter DIV_COUNT = 50_000
)(
    input       clk,
    input       rst,
    output      o_1khz
);
    reg [$clog2(DIV_COUNT):0] counter_reg;
    reg o_1khz_reg;

    assign o_1khz = o_1khz_reg;
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            counter_reg <= 0;
            o_1khz_reg  <= 1'b0;
        end
        else begin
            counter_reg <= counter_reg + 1'b1;
            if(counter_reg == (DIV_COUNT-1)) begin
                counter_reg <= 0;
                o_1khz_reg  <= ~o_1khz_reg;
            end
        end
    end
endmodule

module counter_8(
    input                   clk,
    input                   rst,
    output  [2:0]           digit_sel
);
    reg [2:0]   counter_reg;
    always @(posedge clk, posedge rst) begin
        if(rst) counter_reg <= 3'b000; 
        else    counter_reg <= counter_reg + 1'b1;
    end
    assign digit_sel = counter_reg;
endmodule

module decoder_2x4(
    input       [1:0]   decoder_in,
    output reg  [3:0]   fnd_com
);
    always @(*) begin
        case(decoder_in)
            2'b00   : fnd_com = 4'b1110;            
            2'b01   : fnd_com = 4'b1101;            
            2'b10   : fnd_com = 4'b1011;
            2'b11   : fnd_com = 4'b0111;
            default : fnd_com = 4'b1111;
        endcase 
    end
endmodule

module comparator (
    input   [6:0]       comp_in ,
    output              dot_onoff
);  assign dot_onoff = (comp_in > 50);
endmodule


