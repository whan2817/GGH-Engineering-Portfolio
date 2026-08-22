class Monitor extends uvm_monitor;
    `uvm_component_utils(Monitor)
    uvm_analysis_port #(transaction) send;
    virtual dut_if vif;
    
    transaction tr;
	bit tx_start =0;
	bit send_timing =1;
	bit[9:0] tx_data = 10'h3ff;
	int tx_cnt=0;	
    function new(string name = "Monitor", uvm_component parent = null);
        super.new(name, parent);
        send = new("send", this);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
		tr = transaction::type_id::create("MON_ITEM", this);
        
        if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif_mon", vif)) begin
            `uvm_fatal("MON", "Unable to access ram interface")
        end
    endfunction
    // 매 클럭의 인터페이스 신호를 트랜잭션으로 변환해 분석 포트로 전달한다.
    virtual task run_phase(uvm_phase phase);
		forever begin
			if(vif.protocol == NORM)begin
				send_timing = 1;
			end
			else if(vif.protocol == UART) begin
				
				
				
				
				
				
			end	
			else if(vif.protocol == SPI) begin
			end	
			else if(vif.protocol == I2C) begin
			end	
			else if(vif.protocol == AXI) begin
				send_timing = 1;
			end	

			if(send_timing)begin
				@(posedge vif.i_clk); #1;
				set_monitor_value();
				send.write(tr);
			end
			else begin
				@(posedge vif.i_clk); 
			end
		end
    endtask
	function set_monitor_value ();
        tr.mode			= vif.mode;
        tr.protocol     = vif.protocol;
        tr.i_resetn     = vif.i_resetn;
		tr.i_transfer	= vif.i_transfer;
        tr.i_write    	= vif.i_write;
        tr.i_addr     	= vif.i_addr;
        tr.i_wdata    	= vif.i_wdata;
        tr.o_rdata    	= vif.o_rdata;
        tr.o_ready    	= vif.o_ready;
        tr.w_awaddr   	= vif.w_awaddr;
        tr.w_awvalid  	= vif.w_awvalid;
        tr.w_awready  	= vif.w_awready;
        tr.w_wdata    	= vif.w_wdata;
        tr.w_wvalid   	= vif.w_wvalid;
        tr.w_wready   	= vif.w_wready;
        tr.w_bresp    	= vif.w_bresp;
        tr.w_bvalid   	= vif.w_bvalid;
        tr.w_bready   	= vif.w_bready;
        tr.w_araddr   	= vif.w_araddr;
        tr.w_arvalid  	= vif.w_arvalid;
        tr.w_arready  	= vif.w_arready;
        tr.w_rdata    	= vif.w_rdata;
        tr.w_rvalid   	= vif.w_rvalid;
        tr.w_rready   	= vif.w_rready;
        tr.w_rresp    	= vif.w_rresp;
        tr.w_wstrb    	= vif.w_wstrb;
        tr.io_port  	= vif.io_port;
        tr.io_idr  		= vif.io_idr;
        tr.aw_flag		= vif.w_awvalid && vif.w_awready;
        tr.w_flag  		= vif.w_wvalid  && vif.w_wready;
        tr.b_flag  		= vif.w_bvalid  && vif.w_bready;
        tr.ar_flag 		= vif.w_arvalid && vif.w_arready;
        tr.r_flag  		= vif.w_rvalid  && vif.w_rready;
	endfunction
endclass


