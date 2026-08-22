`timescale 1 ns / 1 ps
module axi_slave_top #
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
				assign idr[i]		= cr[i] ? 1'bz : io_port[i];
			end
		endgenerate
	endmodule


	module gpio_16_v1_0_GPIO #
	(
		

		
		

		
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		
		parameter integer C_S_AXI_ADDR_WIDTH	= 5
	)
	(
		
		output wire [15:0] cr,
		input  wire [15:0] idr,
		output wire [15:0] odr,


		
		

		
		input wire  S_AXI_ACLK,
		
		input wire  S_AXI_ARESETN,
		
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		
    		
    		
		input wire [2 : 0] S_AXI_AWPROT,
		
    		
		input wire  S_AXI_AWVALID,
		
    		
		output wire  S_AXI_AWREADY,
		
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		
    		
    		
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		
    		
		input wire  S_AXI_WVALID,
		
    		
		output wire  S_AXI_WREADY,
		
    		
		output wire [1 : 0] S_AXI_BRESP,
		
    		
		output wire  S_AXI_BVALID,
		
    		
		input wire  S_AXI_BREADY,
		
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		
    		
    		
		input wire [2 : 0] S_AXI_ARPROT,
		
    		
		input wire  S_AXI_ARVALID,
		
    		
		output wire  S_AXI_ARREADY,
		
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		
    		
		output wire [1 : 0] S_AXI_RRESP,
		
    		
		output wire  S_AXI_RVALID,
		
    		
		input wire  S_AXI_RREADY
	);

	
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	
	
	
	
	
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 2;
	
	
	
	
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	
	
	
	

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          
	          
	          
	          
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	
	
	

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	
	
	
	

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          
	          
	          
	          
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	
	
	
	
	
	
	
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	      slv_reg4 <= 0;
	      slv_reg5 <= 0;
	      slv_reg6 <= 0;
	      slv_reg7 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          3'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                
	                
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                
	                
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                
	                
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                
	                
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h4:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                
	                
	                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h5:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                
	                
	                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h6:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                
	                
	                slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h7:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                
	                
	                slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                      slv_reg4 <= slv_reg4;
	                      slv_reg5 <= slv_reg5;
	                      slv_reg6 <= slv_reg6;
	                      slv_reg7 <= slv_reg7;
	                    end
	        endcase
	      end
	  end
	end    

	
	
	
	
	

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; 
	        end                   
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            
	            
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	
	
	
	
	
	

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          
	          axi_arready <= 1'b1;
	          
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	
	
	
	
	
	
	
	
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; 
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	
	
	
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        3'h0   : reg_data_out <= slv_reg0;
	        3'h1   : reg_data_out <= {16'd0,idr};
	        3'h2   : reg_data_out <= slv_reg2;
	        3'h3   : reg_data_out <= slv_reg3;
	        3'h4   : reg_data_out <= slv_reg4;
	        3'h5   : reg_data_out <= slv_reg5;
	        3'h6   : reg_data_out <= slv_reg6;
	        3'h7   : reg_data_out <= slv_reg7;
	        default : reg_data_out <= 0;
	      endcase
	end

	
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      
	      
	      
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     
	        end   
	    end
	end    

	
	assign cr = slv_reg0[15:0];
	
	assign odr = slv_reg2[15:0];
	

	endmodule
