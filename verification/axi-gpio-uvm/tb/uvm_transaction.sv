class transaction extends uvm_sequence_item;
    c_mode mode;
	c_protocol protocol;
    
    
	logic						i_clk		;
	logic 						i_resetn	;
	rand	logic				i_transfer	;
    randc  	logic        		i_write		;
    randc 	logic	[5-1:0] 	i_addr		;
    randc 	logic 	[32-1:0] 	i_wdata		;
	logic			[32-1:0] 	o_rdata		;
    logic						o_ready		;

    
	logic [5-1 : 0]				w_awaddr;
	logic						w_awvalid;
	logic  						w_awready;
	
    
	logic [32-1 : 0]			w_wdata;
	logic [(32/8)-1 : 0]		w_wstrb;
	logic						w_wvalid;
	logic  						w_wready;
    
	logic [1 : 0]				w_bresp;
	logic						w_bvalid;
	logic  						w_bready;
    
	logic [5-1 : 0]				w_araddr;
	logic						w_arvalid;
	logic  						w_arready;
	
    
	
	logic [32-1 : 0]			w_rdata;
	logic						w_rvalid;
	logic  						w_rready;
	logic [1 : 0]				w_rresp;
	
	rand bit random;
	bit aw_flag;
	bit  w_flag;
	bit  b_flag;
	bit ar_flag;
	bit  r_flag;

	logic  		[15:0]			io_idr;
	logic  		[15:0]			io_odr;
	logic  		[15:0]			io_port;
	
	function new(string name = "transaction");
        super.new(name);
    endfunction
	`uvm_object_utils_begin(transaction)
        `uvm_field_enum(c_mode		,mode		,UVM_DEFAULT)
        `uvm_field_enum(c_protocol	,protocol	,UVM_DEFAULT)
    
        `uvm_field_int(i_clk	,UVM_DEFAULT)
        `uvm_field_int(i_resetn,   UVM_DEFAULT)
        `uvm_field_int(i_write,    UVM_DEFAULT)
        `uvm_field_int(i_addr,     UVM_DEFAULT)
        `uvm_field_int(i_wdata,    UVM_DEFAULT)
        `uvm_field_int(i_transfer, UVM_DEFAULT)
        `uvm_field_int(o_rdata,    UVM_DEFAULT)
        `uvm_field_int(o_ready,    UVM_DEFAULT)
    
        `uvm_field_int(w_awaddr,   UVM_DEFAULT)
        `uvm_field_int(w_awvalid,  UVM_DEFAULT)
        `uvm_field_int(w_awready,  UVM_DEFAULT)
    
        `uvm_field_int(w_wdata,    UVM_DEFAULT)
        `uvm_field_int(w_wstrb,    UVM_DEFAULT)
        `uvm_field_int(w_wvalid,   UVM_DEFAULT)
        `uvm_field_int(w_wready,   UVM_DEFAULT)
    
        `uvm_field_int(w_bresp,    UVM_DEFAULT)
        `uvm_field_int(w_bvalid,   UVM_DEFAULT)
        `uvm_field_int(w_bready,   UVM_DEFAULT)
    
        `uvm_field_int(w_araddr,   UVM_DEFAULT)
        `uvm_field_int(w_arvalid,  UVM_DEFAULT)
        `uvm_field_int(w_arready,  UVM_DEFAULT)
    
        `uvm_field_int(w_rdata,    UVM_DEFAULT)
        `uvm_field_int(w_rvalid,   UVM_DEFAULT)
        `uvm_field_int(w_rready,   UVM_DEFAULT)
        `uvm_field_int(w_rresp,    UVM_DEFAULT)
        
		`uvm_field_int(aw_flag,    UVM_DEFAULT)
        `uvm_field_int( w_flag,    UVM_DEFAULT)
        `uvm_field_int( b_flag,    UVM_DEFAULT)
        `uvm_field_int(ar_flag,    UVM_DEFAULT)
        `uvm_field_int( r_flag,    UVM_DEFAULT)
        `uvm_field_int( random,    UVM_DEFAULT)
        `uvm_field_int( io_odr,    UVM_DEFAULT)
        `uvm_field_int( io_port,    UVM_DEFAULT)
        `uvm_field_int( io_idr,    UVM_DEFAULT)
    `uvm_object_utils_end
endclass
