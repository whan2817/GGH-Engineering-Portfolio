`timescale 1ns / 1ps
`include "define.vh"

module data_mem (
    input  logic        clk,
    input  logic        dwe,
    input  logic [ 2:0] mem_mode,
    input  logic [31:0] daddr,
    input  logic [31:0] dwdata,
    output logic [31:0] drdata
);

    logic [31:0] data_ram  [0:255];
    logic [31:0] read_word;

    // Byte 주소를 Word 인덱스로 변환하고 하위 주소 비트로 저장 위치를 선택한다.
    always_ff @(posedge clk) begin
        if (dwe) begin
            case (mem_mode)
                `SB: begin
                    case (daddr[1:0])
                        2'd0: data_ram[daddr[31:2]][7:0]   <= dwdata[7:0];
                        2'd1: data_ram[daddr[31:2]][15:8]  <= dwdata[7:0];
                        2'd2: data_ram[daddr[31:2]][23:16] <= dwdata[7:0];
                        2'd3: data_ram[daddr[31:2]][31:24] <= dwdata[7:0];
                    endcase
                end
                `SH: begin
                    case (daddr[1])
                        1'd0: data_ram[daddr[31:2]][15:0]  <= dwdata[15:0];
                        1'd1: data_ram[daddr[31:2]][31:16] <= dwdata[15:0];
                    endcase
                end
                `SW: data_ram[daddr[31:2]] <= dwdata;
            endcase
        end
    end

    // Load 종류에 따라 Byte 또는 Half-Word를 선택하고 부호 확장을 적용한다.
    always_comb begin
        read_word = data_ram[daddr[31:2]];
        drdata = 32'd0;
        case (mem_mode)
            `LB: begin
                case (daddr[1:0])
                    2'b00: drdata = {{24{read_word[7]}}, read_word[7:0]};
                    2'b01: drdata = {{24{read_word[15]}}, read_word[15:8]};
                    2'b10: drdata = {{24{read_word[23]}}, read_word[23:16]};
                    2'b11: drdata = {{24{read_word[31]}}, read_word[31:24]};

                endcase
            end
            `LH: begin
                case (daddr[1])
                    1'b0: drdata = {{16{read_word[15]}}, read_word[15:0]};
                    1'b1: drdata = {{16{read_word[31]}}, read_word[31:16]};

                endcase
            end
            `LW: drdata = data_ram[daddr[31:2]];
            `LBU: begin
                case (daddr[1:0])
                    2'b00: drdata = {24'd0, read_word[7:0]};
                    2'b01: drdata = {24'd0, read_word[15:8]};
                    2'b10: drdata = {24'd0, read_word[23:16]};
                    2'b11: drdata = {24'd0, read_word[31:24]};
                endcase
            end
            `LHU: begin
                case (daddr[1])
                    1'b0: drdata = {16'd0, read_word[15:0]};
                    1'b1: drdata = {16'd0, read_word[31:16]};
                endcase
            end
        endcase
    end

endmodule
