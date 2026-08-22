`timescale 1 ns / 1 ps

module uart_v1_0_S00_AXI (
    input  wire 			   S_AXI_ACLK,
    input  wire 			   S_AXI_ARESETN,
    input  wire [3 : 0] 	   S_AXI_AWADDR,
    input  wire [2 : 0] 	   S_AXI_AWPROT,
    input  wire 			   S_AXI_AWVALID,
    output wire 			   S_AXI_AWREADY,
    input  wire [31 : 0]       S_AXI_WDATA,
    input  wire [(32/8)-1 : 0] S_AXI_WSTRB,
    input  wire 			   S_AXI_WVALID,
    output wire 			   S_AXI_WREADY,
    output wire [1 : 0]        S_AXI_BRESP,
    output wire 			   S_AXI_BVALID,
    input  wire 			   S_AXI_BREADY,
    input  wire [3 : 0]		   S_AXI_ARADDR,
    input  wire [2 : 0]		   S_AXI_ARPROT,
    input  wire				   S_AXI_ARVALID,
    output wire				   S_AXI_ARREADY,
    output wire [31 : 0]       S_AXI_RDATA,
    output wire [1 : 0]        S_AXI_RRESP,
    output wire				   S_AXI_RVALID,
    input  wire				   S_AXI_RREADY,

    output wire [7:0]          tx_data,
    output wire                tx_valid,
    input  wire                tx_ready,
    input  wire [7:0]          rx_data,
    input  wire                rx_valid,
    output wire                rx_ie,
    output wire                rx_irq
);
    
    reg [3 : 0]  axi_awaddr;
    reg 	     axi_awready;
    reg 	     axi_wready;
    reg [1 : 0]  axi_bresp;
    reg		     axi_bvalid;
    reg [3 : 0]  axi_araddr;
    reg 		 axi_arready;
    reg [31 : 0] axi_rdata;
    reg [1 : 0]  axi_rresp;
    reg 		 axi_rvalid;

    reg [31:0] uart_sr; 
    reg [31:0] uart_tdr; 
    reg [31:0] uart_rdr; 
    reg [31:0] uart_cr; 
    wire	   slv_reg_rden;
    wire	   slv_reg_wren;
    reg [31:0] reg_data_out;
    integer    byte_index;
    reg 	   aw_en;

    reg        tx_valid_r;
    reg        rx_flag;

    assign rx_irq = rx_ie & rx_flag;
    assign tx_data  = uart_tdr[7:0];
    assign tx_valid = tx_valid_r;
    assign rx_ie    = uart_cr[0];

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

	
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
				
				
                axi_awready <= 1'b1;
                aw_en       <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
				
                aw_en       <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awaddr <= 0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
				
                axi_awaddr <= S_AXI_AWADDR;
            end
        end
    end


    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
				
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

	
    // 쓰기 주소와 데이터가 모두 승인된 사이클에 선택된 레지스터를 갱신한다.
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
	

    


    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            
            uart_tdr <= 0;
            
            
            tx_valid_r <= 1'b0;
        end else begin
            tx_valid_r <= 1'b0;
            if (slv_reg_wren && axi_awaddr[3:2] == 2'h1) begin
                uart_tdr <= S_AXI_WDATA;
                tx_valid_r <= 1'b1;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            
            
            uart_rdr <= 0;
            
            rx_flag <= 1'b0;
        end else begin
            if (rx_valid) begin
                uart_rdr <= rx_data;
                rx_flag  <= 1'b1;
            end
            if (slv_reg_rden && axi_araddr[3:2] == 2'h2) begin
                rx_flag <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            
            
            
            uart_cr  <= 0;
        end else begin
            if (slv_reg_wren && axi_awaddr[3:2] == 2'h3) begin
                uart_cr <= S_AXI_WDATA;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 0;
            axi_bresp  <= 2'b0;
        end else begin
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

	
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 32'b0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
				
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;  
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // 읽기 주소가 승인된 사이클에 주소에 대응하는 레지스터 값을 반환한다.
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	
    always @(*) begin
        case (axi_araddr[2+1:2])
			
            2'h0   : reg_data_out  <= {30'b0, rx_flag, tx_ready};
            2'h1   : reg_data_out  <= uart_tdr;
            2'h2   : reg_data_out  <= uart_rdr;
            2'h3   : reg_data_out  <= uart_cr;
            default : reg_data_out <= 0;
        endcase
    end

    
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 0;
        end else begin
            if (slv_reg_rden) begin
                axi_rdata <= reg_data_out; 
            end
        end
    end

endmodule
