`timescale 1ns / 1ps
`include "define.vh"

module rv32i_datapath (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic        rf_we,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    input  logic        alusrc_sel,
    input  logic [ 3:0] alu_control,
    input  logic [ 2:0] rfsrc_sel,
    input  logic [31:0] drdata,
    output logic [31:0] instr_addr,
    output logic [31:0] daddr,
    output logic [31:0] dwdata

);

    logic [31:0]
        rs1,
        rs2,
        alu_result,
        imm_extend,
        alu_rs2_mux,
        wb_out,
        pc_in,
        pc_imm,
        pc_4;
    logic b_taken;

    assign daddr  = alu_result;
    assign dwdata = rs2;

    // ALU, Memory, Immediate, PC 결과 중 Register File에 기록할 값을 선택한다.
    mux_wb U_WB_MUX (
        .in0   (alu_result),
        .in1   (drdata),
        .in2   (imm_extend),
        .in3   (pc_imm),
        .in4   (pc_4),
        .sel   (rfsrc_sel),
        .wb_out(wb_out)
    );


    register_file U_REG_FILE (
        .clk   (clk),
        .raddr1(instr_code[19:15]),
        .raddr2(instr_code[24:20]),
        .rf_we (rf_we),
        .waddr (instr_code[11:7]),
        .wdata (wb_out),
        .rdata1(rs1),
        .rdata2(rs2)
    );

    alu U_ALU (
        .alu_control(alu_control),
        .rs1        (rs1),
        .rs2        (alu_rs2_mux),
        .b_taken    (b_taken),
        .alu_result (alu_result)
    );

    mux_2x1 U_ALU_RS2_MUX (
        .in0    (rs2),
        .in1    (imm_extend),
        .sel    (alusrc_sel),
        .out_mux(alu_rs2_mux)
    );

    imm_extend U_IMM_EXTEND (
        .instr_code(instr_code),
        .imm_extend(imm_extend)
    );

    program_counter U_PROGRAM_COUNTER (
        .clk       (clk),
        .rst       (rst),
        .b_taken   (b_taken),
        .branch    (branch),
        .jal       (jal),
        .jalr      (jalr),
        .rs1       (rs1),
        .pc_in     (instr_addr),
        .imm_extend(imm_extend),
        .pc_out    (instr_addr),
        .pc_imm    (pc_imm),
        .pc_4      (pc_4)
    );

endmodule

module program_counter (
    input  logic        clk,
    input  logic        rst,
    input  logic        b_taken,
    input  logic        branch,
    input  logic        jal,
    input  logic        jalr,
    input  logic [31:0] rs1,
    input  logic [31:0] pc_in,
    input  logic [31:0] imm_extend,
    output logic [31:0] pc_out,
    output logic [31:0] pc_imm,
    output logic [31:0] pc_4
);

    logic [31:0] pc_reg, pc_next, pc_jalr;

    assign pc_out = pc_reg;
    assign pc_imm = imm_extend + pc_jalr;
    assign pc_4   = pc_in + 32'd4;

    // JALR은 rs1을 기준 주소로 사용하고 그 외 분기와 점프는 현재 PC를 사용한다.
    mux_2x1 U_PC_JALR_MUX (
        .in0    (pc_in),
        .in1    (rs1),
        .sel    (jalr),
        .out_mux(pc_jalr)
    );


    mux_2x1 U_PC_SRC_MUX (
        .in0    (pc_4),
        .in1    (pc_imm),
        .sel    (jalr | jal | (b_taken & branch)),
        .out_mux(pc_next)
    );


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            pc_reg <= 0;
        end else begin
            pc_reg <= pc_next;
        end
    end


endmodule

module mux_wb (
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic [31:0] in2,
    input  logic [31:0] in3,
    input  logic [31:0] in4,
    input  logic [ 2:0] sel,
    output logic [31:0] wb_out
);

    always_comb begin
        wb_out = 32'd0;
        case (sel)
            3'd0: wb_out = in0;
            3'd1: wb_out = in1;
            3'd2: wb_out = in2;
            3'd3: wb_out = in3;
            3'd4: wb_out = in4;
        endcase
    end


endmodule

module mux_2x1 (
    input  logic [31:0] in0,
    input  logic [31:0] in1,
    input  logic        sel,
    output logic [31:0] out_mux
);

    assign out_mux = (sel) ? in1 : in0;


endmodule

module imm_extend (
    input  logic [31:0] instr_code,
    output logic [31:0] imm_extend
);

    // 명령어 타입별로 분산된 Immediate 필드를 복원해 32 bit로 확장한다.
    always_comb begin
        imm_extend = 32'd0;
        case (instr_code[6:0])
            `S_TYPE: begin
                imm_extend = {
                    {20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]
                };
            end

            `IL_TYPE, `I_TYPE, `JL_TYPE: begin
                imm_extend = {{20{instr_code[31]}}, instr_code[31:20]};
            end
            `B_TYPE: begin
                imm_extend = {
                    {20{instr_code[31]}},
                    instr_code[7],
                    instr_code[30:25],
                    instr_code[11:8],
                    1'b0
                };
            end
            `UL_TYPE, `UA_TYPE: imm_extend = {{instr_code[31:12]}, 12'h000};
            `J_TYPE:
            imm_extend = {

                {12{instr_code[31]}},
                instr_code[19:12],
                instr_code[20],
                instr_code[30:21],
                1'b0
            };
        endcase
    end

endmodule

module alu (
    input  logic [ 3:0] alu_control,
    input  logic [31:0] rs1,
    input  logic [31:0] rs2,
    output logic        b_taken,
    output logic [31:0] alu_result
);

    // 산술, 논리, 비교, Shift 연산을 ALU 제어값에 따라 수행한다.
    always_comb begin
        alu_result = 0;
        case (alu_control)

            `ADD:  alu_result = rs1 + rs2;
            `SUB:  alu_result = rs1 - rs2;
            `SLL:  alu_result = rs1 << rs2;
            `SLT:  alu_result = ($signed(rs1) < $signed(rs2)) ? 1 : 0;
            `SLTU: alu_result = (rs1 < rs2) ? 1 : 0;
            `XOR:  alu_result = rs1 ^ rs2;
            `SRL:  alu_result = rs1 >> rs2[4:0];
            `SRA:  alu_result = $signed(rs1) >>> rs2[4:0];
            `OR:   alu_result = rs1 | rs2;
            `AND:  alu_result = rs1 & rs2;

        endcase
    end

    // 분기 명령은 signed와 unsigned 비교를 구분해 PC 선택 조건을 생성한다.
    always_comb begin
        b_taken = 0;
        case (alu_control[2:0])
            `BEQ: begin
                if (rs1 == rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BNE: begin
                if (rs1 != rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BLT: begin
                if ($signed(rs1) < $signed(rs2)) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BGE: begin
                if ($signed(rs1) >= $signed(rs2)) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BLTU: begin
                if (rs1 < rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
            `BGEU: begin
                if (rs1 >= rs2) b_taken = 1'b1;
                else b_taken = 1'b0;
            end
        endcase
    end

endmodule

module register_file (
    input  logic        clk,
    input  logic [ 4:0] raddr1,
    input  logic [ 4:0] raddr2,
    input  logic        rf_we,
    input  logic [ 4:0] waddr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2
);

    logic [31:0] register_file[1:31];

    // x0은 항상 0을 반환하고 x1부터 x31까지 실제 저장 공간을 사용한다.
    always_ff @(posedge clk) begin
        if (rf_we) begin
            register_file[waddr] <= wdata;
        end
    end

    assign rdata1 = (!raddr1) ? 32'h0000_0000 : register_file[raddr1];
    assign rdata2 = (!raddr2) ? 32'h0000_0000 : register_file[raddr2];

endmodule
