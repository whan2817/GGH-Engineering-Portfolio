`timescale 1ns / 1ps

module top_rv32i_soc (
    input clk,
    input rst
);
    logic [31:0] instr_code, instr_addr;
    logic [2:0] mem_mode;
    logic dwe;
    logic [31:0] daddr,dwdata,drdata;

    instruction_mem U_INSTR_MEM (.*);
    rv32i_cpu U_RV32I_CPU (.*);

    data_mem U_DATA_RAM (
        .*,
        .daddr   (daddr),
        .dwdata  (dwdata),
        .drdata  (drdata)
    );

endmodule

