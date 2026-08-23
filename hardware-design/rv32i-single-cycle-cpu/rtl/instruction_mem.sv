`timescale 1ns / 1ps

module instruction_mem (
    input  logic [31:0] instr_addr,
    output logic [31:0] instr_code
);

    logic [31:0] instr_rom[0:255];

    // 컴파일된 32 bit 명령어를 ROM에 적재하고 PC를 Word 인덱스로 변환한다.
    initial begin
        $readmemh("instruction_code.mem", instr_rom);
    end

    assign instr_code = instr_rom[instr_addr[31:2]];

endmodule
