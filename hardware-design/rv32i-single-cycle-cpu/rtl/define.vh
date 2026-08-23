// 명령어의 opcode를 타입별로 구분한다.
`define R_TYPE  7'b011_0011
`define I_TYPE  7'b001_0011
`define IL_TYPE 7'b000_0011
`define S_TYPE  7'b010_0011
`define B_TYPE  7'b110_0011
`define JL_TYPE 7'b110_0111
`define J_TYPE  7'b110_1111
`define UL_TYPE 7'b011_0111
`define UA_TYPE 7'b001_0111
// R-Type과 I-Type에서 공통으로 사용하는 ALU 제어값이다.
`define ADD  4'b0_000
`define SUB  4'b1_000
`define SLL  4'b0_001
`define SLT  4'b0_010
`define SLTU 4'b0_011
`define XOR  4'b0_100
`define SRL  4'b0_101
`define SRA  4'b1_101
`define OR   4'b0_110
`define AND  4'b0_111
// 조건 분기와 Load 및 Store의 funct3 값을 정의한다.
`define BEQ  3'b000
`define BNE  3'b001
`define BLT  3'b100
`define BGE  3'b101
`define BLTU 3'b110
`define BGEU 3'b111


`define LB  3'b000
`define LH  3'b001
`define LW  3'b010
`define LBU 3'b100
`define LHU 3'b101


`define SB 3'b000
`define SH 3'b001
`define SW 3'b010

