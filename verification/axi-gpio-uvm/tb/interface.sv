interface dut_if #(
    parameter int C_S00_AXI_ADDR_WIDTH = 5, 
					C_S00_AXI_DATA_WIDTH = 32
) (input logic tb_clk);
	c_mode mode;
	c_protocol protocol;
	logic							i_clk;
    logic        					i_resetn;
    logic        					i_transfer;
    logic        					i_write;
    logic [C_S00_AXI_ADDR_WIDTH-1:0]i_addr;
    logic [C_S00_AXI_DATA_WIDTH-1:0]i_wdata;
    logic [C_S00_AXI_DATA_WIDTH-1:0]o_rdata;
    logic							o_ready;

    
    logic [C_S00_AXI_ADDR_WIDTH-1:0] w_awaddr;
    logic                            w_awvalid;
    logic                            w_awready;

    
    logic [C_S00_AXI_DATA_WIDTH-1:0] w_wdata;
    logic                            w_wvalid;
    logic                            w_wready;

    
    logic [1:0]						 w_bresp;
    logic       					 w_bvalid;
    logic       					 w_bready;

    
    logic [C_S00_AXI_ADDR_WIDTH-1:0] w_araddr;
    logic                            w_arvalid;
    logic                            w_arready;

    
    logic [C_S00_AXI_DATA_WIDTH-1:0] w_rdata;
    logic                            w_rvalid;
    logic                            w_rready;
    logic [1:0]                      w_rresp;
	assign i_clk = tb_clk;
    
	logic [3:0]  w_wstrb;
    wire  [15:0] io_port;       
    logic [15:0] io_idr;

    
    clocking drv_cb @(negedge i_clk);
		output mode;
		output protocol;
        output i_resetn;
        output i_transfer;
        output i_write;
        output i_addr;
        output i_wdata;
        output w_wstrb;
		output io_port;
		output io_idr;
    endclocking

	modport drv_mp (
	    clocking drv_cb
	);

	modport mon_mp (
		input i_clk,
		input mode,
		input protocol,
        input i_resetn,
        input i_transfer,
        input i_write,
        input i_addr,
        input i_wdata,
        input o_rdata,
        input o_ready,
        input w_awaddr,
        input w_awvalid,
        input w_awready,
        input w_wdata,
        input w_wvalid,
        input w_wready,
        input w_bresp,
        input w_bvalid,
        input w_bready,
        input w_araddr,
        input w_arvalid,
        input w_arready,
        input w_rdata,
        input w_rvalid,
        input w_rready,
        input w_rresp,
		input w_wstrb
	);

endinterface
