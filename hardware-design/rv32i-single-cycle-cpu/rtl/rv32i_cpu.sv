`timescale 1ns / 1ps

module rv32i_cpu (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] instr_code,
    input  logic [31:0] drdata,
    output logic [31:0] instr_addr,
    output logic [ 2:0] mem_mode,
    output logic        dwe,
    output logic [31:0] daddr,
    output logic [31:0] dwdata
);

    logic rf_we, alusrc_sel;
    logic [2:0] rfsrc_sel;
    logic [3:0] alu_control;
    logic branch, jal, jalr;

    rv32i_control_unit U_CONTROL_UNIT (.*);
    rv32i_datapath U_DATA_PATH (.*);

endmodule

