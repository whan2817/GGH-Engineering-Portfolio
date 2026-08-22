`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;
import dut_pkg::*;
`include "../TB/interface.sv"

module tb_top;
	parameter int C_S00_AXI_ADDR_WIDTH = 5;
    parameter int C_S00_AXI_DATA_WIDTH = 32;
    logic clk;

	my_report_server svr;
    dut_if tb_if(clk);

	initial begin
		$fsdbDumpfile("./wave.fsdb");
		$fsdbDumpvars(0, tb_top);
		$fsdbDumpMDA(0, tb_top);
	end	

	axi_master u_axi_master(
		.ACLK			(tb_if.i_clk		),
    	.ARESETn		(tb_if.i_resetn	),
		.transfer		(tb_if.i_transfer	),
    	.addr			(tb_if.i_addr		),
    	.wdata			(tb_if.i_wdata	),
    	.write			(tb_if.i_write	),
		.ready			(tb_if.o_ready	),
    	.rdata			(tb_if.o_rdata	),
    	.AWADDR			(tb_if.w_awaddr	),
    	.AWVALID		(tb_if.w_awvalid	),
    	.AWREADY		(tb_if.w_awready	),
    	.WDATA			(tb_if.w_wdata	),
    	.WVALID			(tb_if.w_wvalid	),
    	.WREADY			(tb_if.w_wready	),
    	.BRESP			(tb_if.w_bresp 	),
    	.BVALID			(tb_if.w_bvalid	),
    	.BREADY			(tb_if.w_bready	),
    	.ARADDR			(tb_if.w_araddr	),
    	.ARVALID		(tb_if.w_arvalid	),
    	.ARREADY		(tb_if.w_arready	),
    	.RDATA			(tb_if.w_rdata	),
    	.RVALID			(tb_if.w_rvalid	),
    	.RREADY			(tb_if.w_rready	),
    	.RRESP			(tb_if.w_rresp	));

	axi_slave_top # (
		.C_S00_AXI_DATA_WIDTH	(C_S00_AXI_DATA_WIDTH),
		.C_S00_AXI_ADDR_WIDTH	(C_S00_AXI_ADDR_WIDTH))
	u_axi_slave(
		.io_port				(tb_if.io_port	),
		.gpio_aclk				(tb_if.i_clk	),
		.gpio_aresetn			(tb_if.i_resetn	),
		.gpio_awaddr			(tb_if.w_awaddr	),
		.gpio_awvalid			(tb_if.w_awvalid),
		.gpio_awready			(tb_if.w_awready),
		.gpio_awprot			(3'd0			),
		.gpio_wdata				(tb_if.w_wdata	),
		.gpio_wvalid			(tb_if.w_wvalid	),
		.gpio_wready			(tb_if.w_wready	),
		.gpio_wstrb				(tb_if.w_wstrb	),
		.gpio_bresp				(tb_if.w_bresp	),
		.gpio_bvalid			(tb_if.w_bvalid	),
		.gpio_bready			(tb_if.w_bready	),
		.gpio_araddr			(tb_if.w_araddr	),
		.gpio_arvalid			(tb_if.w_arvalid),
		.gpio_arready			(tb_if.w_arready),
		.gpio_arprot			(3'd0			),
		.gpio_rdata				(tb_if.w_rdata	),
		.gpio_rvalid			(tb_if.w_rvalid	),
		.gpio_rready			(tb_if.w_rready	),
		.gpio_rresp				(tb_if.w_rresp	));


    initial begin
		svr = new();
		my_report_server::set_server(svr);
        uvm_config_db#(virtual dut_if.drv_mp)::set( null, "*", "vif_drv", tb_if.drv_mp);
        
        uvm_config_db#(virtual dut_if)::set( null, "*", "vif_mon", tb_if);
        run_test("Dut_test");
    end
    
	initial begin
        clk = 1'b0; 
		
		loop = 10000; mode_sel = "ALL";
		forever begin #5 clk = ~clk; end
    end

endmodule
