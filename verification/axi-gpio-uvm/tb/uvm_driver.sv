class Driver extends uvm_driver #(transaction);
    `uvm_component_utils(Driver)
    virtual dut_if.drv_mp vif;
    transaction tr;
	c_mode b_mode;

    function new(string name = "driver",  uvm_component parent = null);
        super.new(name, parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual dut_if.drv_mp)::get(this, "", "vif_drv", vif)) begin
            `uvm_fatal("DRV", "Unable to access interface.")
        end
    endfunction
    virtual task run_phase(uvm_phase phase);
        forever begin seq_item_port.get_next_item(tr);
			case (tr.mode)
				RESET		:begin drv_reset_value();	end
				TEST_START	:begin set_init_value();	end
				WRITE		:begin set_write_value();	end
				IO			:begin set_gpio_value();	end
				READ		:begin set_read_value();  	end
				TEST_END	:begin set_end_value();   	end
			endcase
			b_mode = tr.mode;
			seq_item_port.item_done();
        end
    endtask
	task driving_mode (); 
		vif.drv_cb.mode		<= tr.mode;
		vif.drv_cb.protocol <= tr.protocol;
		if(tr.protocol == UART)		begin drv_uart();end
		else if(tr.protocol == SPI) begin drv_spi(); end
		else if(tr.protocol == I2C) begin drv_i2c(); end
		else if(tr.protocol == AXI) begin drv_axi(); end
		
		else if(tr.protocol == NORM)begin drv_norm(); end
	endtask
	
	task set_init_value (); 
		tr.i_write    = 1'b0;
		tr.i_addr     = 5'd0;
		tr.i_wdata    = 32'd0;
		tr.i_transfer = 1'b0;
		for(int i=0; i < 16; i ++) if(!iocr[i]) tr.io_port[i] = 1'b0;
		for(int i=0; i < 16; i ++) if(!iocr[i]) tr.io_idr[i] = 1'b0;
		driving_mode (); 
	endtask

	task set_end_value (); 
		tr.i_write    = 1'b0;
		tr.i_addr     = 5'hf;
		tr.i_wdata    = 32'hffff;
		tr.i_transfer = 1'b0;
		driving_mode (); 
	endtask

	task drv_reset_value(); 
		`uvm_info("DRV",$sformatf("RESET"), UVM_LOW)
		vif.drv_cb.mode		<= tr.mode;
		vif.drv_cb.protocol <= tr.protocol;
		vif.drv_cb.i_resetn    <= 1'b1;
		@(vif.drv_cb);
		vif.drv_cb.i_resetn    <= 1'b0;
		@(vif.drv_cb);
		vif.drv_cb.i_resetn    <= 1'b1;
	endtask

	task set_write_value (); 
		tr.i_write    = 1'b1;
		tr.i_transfer = 1'b1;
		if(tr.random)begin
			std::randomize(tr.i_transfer);	
			std::randomize(tr.i_addr);	
			std::randomize(tr.i_wdata);	
			std::randomize(tr.w_wstrb);	
		end
		if(tr.i_addr == 1) tr.i_addr = 0;
		driving_mode (); 
	endtask
	
	task set_gpio_value (); 
		tr.i_transfer = 1'b0;
		for(int i=0; i < 16; i++)begin
			if(!iocr[i]) tr.io_port[i] = 1'b1;
			if(!iocr[i]) tr.io_idr[i] = 1'b1;
		end
		if(tr.random)begin
			std::randomize(tr.w_wstrb);	
			for(int i=0; i < 16; i++)begin
				if(!iocr[i]) tr.io_port[i] = $urandom;
				if(!iocr[i]) tr.io_idr[i] = tr.io_port[i];
			end
		end
		driving_gpio_mode (); 
	endtask

	task set_read_value (); 
		tr.i_write    = 1'b0;
		tr.i_transfer = 1'b1;
		if(tr.random)begin
			std::randomize(tr.i_transfer);	
			std::randomize(tr.i_addr);	
		end
		driving_mode (); 
	endtask

	task drv_norm ();
		@(vif.drv_cb);
		vif.drv_cb.i_write    <= tr.i_write;
		vif.drv_cb.i_addr     <= tr.i_addr;
		vif.drv_cb.i_wdata    <= tr.i_wdata;
		vif.drv_cb.i_transfer <= tr.i_transfer;	
		for(int i=0; i < 16; i++)begin
			if(!iocr[i]) vif.drv_cb.io_port[i] <= tr.io_port[i];
			else vif.drv_cb.io_port[i] <= 1'bz;  
			if(!iocr[i]) vif.drv_cb.io_idr[i]  <= tr.io_idr[i];
			else vif.drv_cb.io_idr[i] <= 1'bz;  
		end
	endtask
	
    // 시퀀스 항목의 명령에 따라 AXI 읽기, 쓰기 또는 GPIO 입력 구동을 수행한다.
	task drv_axi ();
	    @(vif.drv_cb);
		vif.drv_cb.mode		<= tr.mode;
		vif.drv_cb.protocol <= tr.protocol;
		@(vif.drv_cb);
		vif.drv_cb.i_transfer <= tr.i_transfer;
		vif.drv_cb.i_write    <= tr.i_write;
	    @(vif.drv_cb);
	    vif.drv_cb.i_transfer <= 1'b0;
		vif.drv_cb.w_wstrb    <= tr.w_wstrb;
		vif.drv_cb.i_addr     <= tr.i_addr;
		vif.drv_cb.i_wdata    <= tr.i_wdata;
	endtask
	
	task driving_gpio_mode ();
		if(b_mode != IO)begin
			@(vif.drv_cb);
			@(vif.drv_cb);
		end
		@(vif.drv_cb);
		vif.drv_cb.mode		<= tr.mode;
		vif.drv_cb.protocol <= tr.protocol;
		vif.drv_cb.i_transfer <= 1'b0;
		for(int i=0; i < 16; i++)begin
			if(!iocr[i]) vif.drv_cb.io_port[i] <= tr.io_port[i];
			else vif.drv_cb.io_port[i] <= 1'bz;  
			if(!iocr[i]) vif.drv_cb.io_idr[i]  <= tr.io_idr[i];
			else vif.drv_cb.io_idr[i] <= 1'bz;  
		end
	endtask
	
	task drv_uart ();
		$display("Need Change");
        
        
        
        
        
	endtask
	task drv_spi ();
		$display("Need Change");
	endtask
	task drv_i2c ();
		$display("Need Change");
	endtask
endclass
	
