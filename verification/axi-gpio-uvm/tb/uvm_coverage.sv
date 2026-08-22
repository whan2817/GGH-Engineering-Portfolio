class Coverage extends uvm_component;
    `uvm_component_utils(Coverage)
    transaction tr;
	uvm_tlm_analysis_fifo #(transaction) cov_fifo;

    covergroup cg;
		option.per_instance = 1;
		option.auto_bin_max = 64;

		cp_mode : coverpoint tr.mode {
            bins mode_reset = {RESET};
            bins mode_wirte = {WRITE};
            bins mode_read = {READ};
            bins mode_IO = {IO};
		}
        cp_protocol : coverpoint tr.protocol {
            bins protocol_normal = {NORM};
            bins protocol_axi = {AXI};
            bins protocol_gpio = {GPIO};
		}
        cp_i_resetn : coverpoint tr.i_resetn {
            bins reset_assert  = {1'b0};
            bins reset_release = {1'b1};
        }
        cp_i_transfer : coverpoint tr.i_transfer iff (tr.i_resetn === 1'b1) {
            bins idle   = {1'b0};
            bins active = {1'b1};
        }
        cp_i_write : coverpoint tr.i_write iff ( tr.i_resetn === 1'b1 && 
			tr.i_transfer === 1'b1) { 
			bins read  = {1'b0}; 
			bins write = {1'b1};
        }
        cp_i_addr : coverpoint tr.i_addr[4:2] iff ( tr.i_resetn === 1'b1 &&
            tr.i_transfer === 1'b1) {
            bins cr       = {3'd0};
            bins idr      = {3'd1};
            bins odr      = {3'd2};
            bins reg0     = {3'd3};
            bins reg1     = {3'd4};
            bins reg2     = {3'd5};
            bins reg3     = {3'd6};
            bins reg4     = {3'd7};
        }
        cp_o_ready : coverpoint tr.o_ready iff ( tr.i_resetn === 1'b1 ) { 
			bins not_ready = {1'b0}; bins ready     = {1'b1}; 
		}

        
        cp_aw_state : coverpoint {tr.w_awvalid, tr.w_awready} iff (tr.i_resetn === 1'b1) {
            bins idle       = {2'b00};
            bins handshake  = {2'b11};
        }
        cp_w_state : coverpoint {tr.w_wvalid, tr.w_wready} iff (tr.i_resetn === 1'b1) {
            bins idle       = {2'b00};
            bins handshake  = {2'b11};
        }
        cp_b_state : coverpoint {tr.w_bvalid, tr.w_bready} iff (tr.i_resetn === 1'b1) {
            bins idle       = {2'b00};
            bins handshake  = {2'b11};
        }

        cp_w_awaddr : coverpoint tr.w_awaddr iff (
            tr.i_resetn === 1'b1 &&
            tr.w_awvalid === 1'b1 &&
            tr.w_awready === 1'b1) {
			bins cr       = {3'd0};
            bins odr      = {3'd2};
            bins reg0     = {3'd3};
            bins reg1     = {3'd4};
            bins reg2     = {3'd5};
            bins reg3     = {3'd6};
            bins reg4     = {3'd7};
        }
        cp_w_wdata : coverpoint tr.w_wdata iff ( tr.i_resetn === 1'b1 && 
			tr.w_wvalid === 1'b1 && tr.w_wready === 1'b1
        ); 

        cp_w_wstrb : coverpoint tr.w_wstrb iff ( tr.i_resetn === 1'b1 &&
            tr.w_wvalid === 1'b1 &&
            tr.w_wready === 1'b1
        ) {
            bins none      = {4'b0000};
            bins byte_en[] = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
            bins full      = {4'b1111};
            bins others    = default;
        }

        
        cp_ar_state : coverpoint {tr.w_arvalid, tr.w_arready} iff (tr.i_resetn === 1'b1) {
            bins idle       = {2'b00};
            bins handshake  = {2'b11};
        }
        cp_r_state : coverpoint {tr.w_rvalid, tr.w_rready} iff (tr.i_resetn === 1'b1) {
            bins idle       = {2'b00};
            bins handshake  = {2'b11};
        }

        cp_w_araddr : coverpoint tr.w_araddr iff ( tr.i_resetn === 1'b1 &&
            tr.w_arvalid === 1'b1 &&
            tr.w_arready === 1'b1) {
			bins cr       = {3'd0};
            bins idr      = {3'd1};
            bins odr      = {3'd2};
            bins reg0     = {3'd3};
            bins reg1     = {3'd4};
            bins reg2     = {3'd5};
            bins reg3     = {3'd6};
            bins reg4     = {3'd7};
        }
        cp_w_rdata : coverpoint tr.w_rdata iff ( tr.i_resetn === 1'b1 &&
            tr.w_rvalid === 1'b1 &&
            tr.w_rready === 1'b1
        );

		
        cp_aw_flag : coverpoint tr.aw_flag iff (tr.i_resetn === 1'b1) {
            bins off = {1'b0}; bins on  = {1'b1};
        }
        cp_w_flag : coverpoint tr.w_flag iff (tr.i_resetn === 1'b1) {
            bins off = {1'b0}; bins on  = {1'b1};
        }
        cp_b_flag : coverpoint tr.b_flag iff (tr.i_resetn === 1'b1) {
            bins off = {1'b0}; bins on  = {1'b1};
        }
        cp_ar_flag : coverpoint tr.ar_flag iff (tr.i_resetn === 1'b1) {
            bins off = {1'b0}; bins on  = {1'b1};
        }
        cp_r_flag : coverpoint tr.r_flag iff (tr.i_resetn === 1'b1) {
            bins off = {1'b0}; bins on  = {1'b1};
        }

	endgroup
    
	function new(string name = "Coverage", uvm_component parent = null);
        super.new(name, parent);
		cov_fifo = new("cov_fifo", this);
        cg = new();
    endfunction
    
	virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

	function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COVERAGE_REPORT", $sformatf("[Functional Coverage = %f]", cg.get_inst_coverage()), UVM_LOW)
    endfunction

	virtual task run_phase(uvm_phase phase);
        forever begin
			cov_fifo.get(tr);
			cg.sample(); 
        end
    endtask
endclass


