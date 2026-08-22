class Scoreboard extends uvm_scoreboard;
    `uvm_component_utils(Scoreboard)
	transaction tr=new();
	uvm_analysis_imp #(transaction, Scoreboard) recv;
	
	logic [7:0] ram [0:255] ;
	logic [31:0] s_register [0:7] = '{default: 32'd0};
	logic [31:0] exp_rdata;
	logic [3:0] raddr;
	logic [3:0] waddr;
	logic [15:0] io_port;
	bit r_mode,w_mode;
	int r_check,io_check;
    
	function new(string name = "Scoreboard", uvm_component parent = null);
        super.new(name, parent);
		recv = new("recv", this);
    endfunction
    
    // 관측한 트랜잭션으로 기준 레지스터 값을 갱신하고 DUT 출력과 비교한다.
	virtual function void write(transaction tr);
		if(!tr.i_resetn) begin `uvm_info("SCB",$sformatf("RESET"), UVM_LOW)
			s_register  = '{default: 32'd0};
		end
		else begin
			iocr = s_register[0][15:0];
			if(tr.i_transfer && !tr.i_write)begin read_num++; end  
			if(tr.r_flag) begin raddr = tr.w_araddr[4:2];	
				if(raddr == 3'd1)begin s_register[1][31:16]= 16'd0; 
					for(int i = 0; i < 16; i++)begin 
						 s_register[1][i] = (s_register[0][i]) ? 1'bz : tr.io_port[i]; 
					end
				end
				exp_rdata =  s_register[raddr];
				if(exp_rdata === tr.o_rdata)	`uvm_info ("SCB",$sformatf("[READ][ADDR : %d][EXP_DATA : %b DUT : %b] [PASS]",raddr,exp_rdata , tr.o_rdata), UVM_LOW)
				else							`uvm_error("SCB",$sformatf("[READ][ADDR : %d][EXP_DATA : %b DUT : %b] [FAIL]",raddr,exp_rdata , tr.o_rdata))
				
			end

			if(tr.i_transfer && tr.i_write)begin  write_num++; end  
			if(tr.w_flag) begin waddr = tr.w_awaddr[4:2]; 
				
				if(waddr != 3'd1)begin 
					if(tr.w_wstrb[0]) s_register[tr.w_awaddr[4:2]][7 : 0]= tr.w_wdata[7 : 0];	
					if(tr.w_wstrb[1]) s_register[tr.w_awaddr[4:2]][15: 8]= tr.w_wdata[15: 8];	
					if(tr.w_wstrb[2]) s_register[tr.w_awaddr[4:2]][23:16]= tr.w_wdata[23:16];	
					if(tr.w_wstrb[3]) s_register[tr.w_awaddr[4:2]][31:24]= tr.w_wdata[31:24];	
				end
				else begin 
				end
				`uvm_info ("SCB",$sformatf("[WRITE][ADDR : %d][DUT : %h]",waddr , tr.w_wdata), UVM_LOW)
			end	
			if(tr.mode == IO && !tr.r_flag && !tr.w_flag)begin io_num++;
				for(int i = 0; i < 16; i++)begin io_port[i] = (s_register[0][i]) ? s_register[2][i] : tr.io_idr[i]; end
				if(io_port === tr.io_port)	`uvm_info ("SCB",$sformatf("[IO_PORT][CR: %h][EXP: %h DUT: %h] [PASS]",iocr,io_port , tr.io_port), UVM_LOW)
				else						`uvm_error("SCB",$sformatf("[IO_PORT][CR: %h][EXP: %b DUT: %b] [FAIL]",iocr,io_port , tr.io_port))
			end

			if(tr.r_flag) begin 	
				r_check++;
				if(exp_rdata === tr.o_rdata)pass_num++; else fail_num++;
			end

			if(tr.mode == IO && !tr.r_flag && !tr.w_flag)begin
				if(io_port === tr.io_port)	pass_num++; else fail_num++;
			end
		end
    endfunction
	function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB_REPORT", $sformatf("[READ_NUM :	%4d] [WRITE_NUM:	%4d]	[IO_NUM  :	%5d]", read_num,write_num,io_num), UVM_LOW)
        `uvm_info("SCB_REPORT", $sformatf("[CHECK_NUM:	%4d] [PASS_NUM :	%4d]	[FAIL_NUM:	%5d]", read_num+io_num,pass_num,fail_num), UVM_LOW)
    endfunction


endclass

