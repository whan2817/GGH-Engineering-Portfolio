`timescale 1ns / 1ps
`include "define.vh"

module rv32i_control_unit (
    input  logic [31:0] instr_code,
    output logic        rf_we,
    output logic        alusrc_sel,
    output logic [ 3:0] alu_control,
    output logic [ 2:0] rfsrc_sel,
    output logic [ 2:0] mem_mode,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic        dwe
);

    logic [6:0] funct7;
    logic [2:0] funct3;
    logic [6:0] opcode;

    assign funct7 = instr_code[31:25];
    assign funct3 = instr_code[14:12];
    assign opcode = instr_code[6:0];

    // 파형에서 opcode와 ALU 및 분기 종류를 명령어 이름으로 표시하는 디버그 타입이다.
    typedef enum logic [6:0] {
        DBG_R_TYPE  = `R_TYPE,
        DBG_S_TYPE  = `S_TYPE,
        DBG_IL_TYPE = `IL_TYPE,
        DBG_I_TYPE  = `I_TYPE,
        DBG_B_TYPE  = `B_TYPE,
        DBG_UL_TYPE = `UL_TYPE,
        DBG_UA_TYPE = `UA_TYPE,
        DBG_JL_TYPE = `JL_TYPE,
        DBG_J_TYPE  = `J_TYPE
    } opcede_dbg_e;
    opcede_dbg_e opcode_dbg;

    assign opcode_dbg = opcede_dbg_e'(opcode);

    typedef enum logic [3:0] {
        DBG_ADD  = `ADD,
        DBG_SUB  = `SUB,
        DBG_SLL  = `SLL,
        DBG_SLT  = `SLT,
        DBG_SLTU = `SLTU,
        DBG_XOR  = `XOR,
        DBG_SRL  = `SRL,
        DBG_SRA  = `SRA,
        DBG_OR   = `OR,
        DBG_AND  = `AND
    } r_type_dbg_e;
    r_type_dbg_e r_type_dbg;

    typedef enum logic [2:0] {
        DBG_BEQ  = `BEQ,
        DBG_BNE  = `BNE,
        DBG_BLT  = `BLT,
        DBG_BGE  = `BGE,
        DBG_BLTU = `BLTU,
        DBG_BGEU = `BGEU
    } b_type_dbg_e;
    b_type_dbg_e b_type_dbg;

    assign r_type_dbg = r_type_dbg_e'(alu_control);
    assign b_type_dbg = b_type_dbg_e'(alu_control);

    // opcode와 funct 필드를 해석해 Datapath와 Memory의 제어 신호를 생성한다.
    always_comb begin
        rf_we       = 1'b0;
        alusrc_sel  = 1'b0;
        alu_control = 4'b0;
        rfsrc_sel   = 3'd0;
        mem_mode    = 3'b0;
        branch      = 1'b0;
        jal         = 1'b0;
        jalr        = 1'b0;
        dwe         = 1'b0;
        case (opcode)
            `R_TYPE: begin
                rf_we       = 1'b1;
                alusrc_sel  = 1'b0;
                alu_control = {funct7[5], funct3};
                rfsrc_sel   = 3'd0;
                mem_mode    = 3'b0;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                dwe         = 1'b0;
            end
            `S_TYPE: begin
                rf_we       = 1'b0;
                alusrc_sel  = 1'b1;
                alu_control = `ADD;
                rfsrc_sel   = 3'd0;
                mem_mode    = funct3;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                dwe         = 1'b1;
            end
            `IL_TYPE: begin
                rf_we       = 1'b1;
                alusrc_sel  = 1'b1;
                alu_control = `ADD;
                rfsrc_sel   = 3'd1;
                mem_mode    = funct3;
                branch      = 1'b0;
                jal         = 1'b0;
                jalr        = 1'b0;
                dwe         = 1'b0;
            end
            `I_TYPE: begin
                rf_we      = 1'b1;
                alusrc_sel = 1'b1;
                if (funct3 == 3'b101)
                    alu_control = {funct7[5], funct3};
                else alu_control = {1'b0, funct3};
                rfsrc_sel = 3'd0;
                mem_mode  = 1'b0;
                branch    = 1'b0;
                jal       = 1'b0;
                jalr      = 1'b0;
                dwe       = 1'b0;
            end
            `B_TYPE: begin
                rf_we       = 1'b0;
                alusrc_sel  = 1'b0;
                alu_control = {1'b0, funct3};
                rfsrc_sel   = 3'd0;
                mem_mode    = 1'b0;
                branch      = 1'b1;
                jal         = 1'b0;
                jalr        = 1'b0;
                dwe         = 1'b0;
            end
            `UL_TYPE, `UA_TYPE: begin
                rf_we       = 1'b1;
                alusrc_sel  = 1'b0;
                alu_control = 4'b0;
                if (opcode == `UL_TYPE) rfsrc_sel = 3'd2;
                else rfsrc_sel = 3'd3;
                mem_mode = 1'b0;
                branch   = 1'b0;
                jal      = 1'b0;
                jalr     = 1'b0;
                dwe      = 1'b0;
            end
            `J_TYPE, `JL_TYPE: begin
                rf_we       = 1'b1;
                alusrc_sel  = 1'b0;
                alu_control = 4'b0;
                rfsrc_sel   = 3'd4;
                mem_mode    = 1'b0;
                branch      = 1'b0;
                jal         = 1'b1;
                if (opcode == `J_TYPE) begin
                    jalr = 1'b0;
                end else begin
                    jalr = 1'b1;
                end
                dwe = 1'b0;
            end
        endcase
    end

endmodule
