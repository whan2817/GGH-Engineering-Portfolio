`timescale 1 ns / 1 ps

	module gpio_16_v1_0 #
	(
		

		
		


		
		parameter integer C_GPIO_DATA_WIDTH	= 32,
		parameter integer C_GPIO_ADDR_WIDTH	= 5
	)
	(
		
		inout wire [15:0] io_port,
		
		


		
		input wire  gpio_aclk,
		input wire  gpio_aresetn,
		input wire [C_GPIO_ADDR_WIDTH-1 : 0] gpio_awaddr,
		input wire [2 : 0] gpio_awprot,
		input wire  gpio_awvalid,
		output wire  gpio_awready,
		input wire [C_GPIO_DATA_WIDTH-1 : 0] gpio_wdata,
		input wire [(C_GPIO_DATA_WIDTH/8)-1 : 0] gpio_wstrb,
		input wire  gpio_wvalid,
		output wire  gpio_wready,
		output wire [1 : 0] gpio_bresp,
		output wire  gpio_bvalid,
		input wire  gpio_bready,
		input wire [C_GPIO_ADDR_WIDTH-1 : 0] gpio_araddr,
		input wire [2 : 0] gpio_arprot,
		input wire  gpio_arvalid,
		output wire  gpio_arready,
		output wire [C_GPIO_DATA_WIDTH-1 : 0] gpio_rdata,
		output wire [1 : 0] gpio_rresp,
		output wire  gpio_rvalid,
		input wire  gpio_rready
	);
		wire [15:0] cr;
		wire [15:0] idr;
		wire [15:0] odr;


	gpio_16_v1_0_GPIO # ( 
		.C_S_AXI_DATA_WIDTH(C_GPIO_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_GPIO_ADDR_WIDTH)
	) gpio_16_v1_0_GPIO_inst (
		.cr(cr),
		.idr(idr),
		.odr(odr),
		.S_AXI_ACLK(gpio_aclk),
		.S_AXI_ARESETN(gpio_aresetn),
		.S_AXI_AWADDR(gpio_awaddr),
		.S_AXI_AWPROT(gpio_awprot),
		.S_AXI_AWVALID(gpio_awvalid),
		.S_AXI_AWREADY(gpio_awready),
		.S_AXI_WDATA(gpio_wdata),
		.S_AXI_WSTRB(gpio_wstrb),
		.S_AXI_WVALID(gpio_wvalid),
		.S_AXI_WREADY(gpio_wready),
		.S_AXI_BRESP(gpio_bresp),
		.S_AXI_BVALID(gpio_bvalid),
		.S_AXI_BREADY(gpio_bready),
		.S_AXI_ARADDR(gpio_araddr),
		.S_AXI_ARPROT(gpio_arprot),
		.S_AXI_ARVALID(gpio_arvalid),
		.S_AXI_ARREADY(gpio_arready),
		.S_AXI_RDATA(gpio_rdata),
		.S_AXI_RRESP(gpio_rresp),
		.S_AXI_RVALID(gpio_rvalid),
		.S_AXI_RREADY(gpio_rready)
	);

	
	gpio u_gpio(
		.cr(cr),
		.idr(idr),
		.odr(odr),
		.io_port(io_port)
	);

	

	endmodule

	module gpio (
		input wire [15:0] cr,
		output wire[15:0] idr,
		input wire [15:0] odr,
		
		inout wire [15:0] io_port
	);
		genvar i;
	
		generate 
			for(i =0; i < 16; i=i+1) begin
				assign io_port[i]	= cr[i] ? odr[i] : 1'bz;
				assign idr[i]		= io_port[i];
			end
		endgenerate
	endmodule
