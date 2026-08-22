`timescale 1 ns / 1 ps

module SPI_v1_0_S00_AXI #(
    

    
    

    
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    
    input  wire [7:0] rx_data,
    input  wire       busy,
    input  wire       done,
    output wire       start,
    output wire [7:0] tx_data,
    output wire       cs_manual_en,
    output wire       cs_n_manual,
    
    

    
    input wire S_AXI_ACLK,
    
    input wire S_AXI_ARESETN,
    
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    
    
    
    input wire [2 : 0] S_AXI_AWPROT,
    
    
    input wire S_AXI_AWVALID,
    
    
    output wire S_AXI_AWREADY,
    
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    
    
    
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    
    
    input wire S_AXI_WVALID,
    
    
    output wire S_AXI_WREADY,
    
    
    output wire [1 : 0] S_AXI_BRESP,
    
    
    output wire S_AXI_BVALID,
    
    
    input wire S_AXI_BREADY,
    
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    
    
    
    input wire [2 : 0] S_AXI_ARPROT,
    
    
    input wire S_AXI_ARVALID,
    
    
    output wire S_AXI_ARREADY,
    
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    
    
    output wire [1 : 0] S_AXI_RRESP,
    
    
    output wire S_AXI_RVALID,
    
    
    input wire S_AXI_RREADY
);

    
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    reg axi_awready;
    reg axi_wready;
    reg [1 : 0] axi_bresp;
    reg axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    reg axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    reg [1 : 0] axi_rresp;
    reg axi_rvalid;

    
    
    
    
    
    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;
    
    
    
    
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;  
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;  
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;  
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;  
    wire slv_reg_rden;
    wire slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer byte_index;
    reg aw_en;

    wire write_ctrl;
    wire start_pulse;

    
    reg done_latched;
    reg [7:0] rx_data_latched;

    

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
                aw_en <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
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

    assign write_ctrl = slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0);

    assign start_pulse = write_ctrl && S_AXI_WDATA[0];

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
        end else begin
            if (slv_reg_wren) begin
                case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                    2'h0:
                    for (
                        byte_index = 0;
                        byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        
                        
                        slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    2'h1:
                    for (
                        byte_index = 0;
                        byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        
                        
                        slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    2'h2:
                    for (
                        byte_index = 0;
                        byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        
                        
                        slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    2'h3:
                    for (
                        byte_index = 0;
                        byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        
                        
                        slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    default: begin
                        slv_reg0 <= slv_reg0;
                        slv_reg1 <= slv_reg1;
                        slv_reg2 <= slv_reg2;
                        slv_reg3 <= slv_reg3;
                    end
                endcase
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            done_latched    <= 1'b0;
            rx_data_latched <= 8'd0;
        end else begin
            if (start_pulse) begin
                done_latched <= 1'b0;
            end else if (done) begin
                done_latched    <= 1'b1;
                rx_data_latched <= rx_data;
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
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            2'h0:    reg_data_out = slv_reg0;  
            2'h1:    reg_data_out = slv_reg1;  
            2'h2:    reg_data_out = {30'b0, busy, done_latched};  
            2'h3:    reg_data_out = {24'b0, rx_data_latched};  
            default: reg_data_out = 0;
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

    
    
    

    assign write_ctrl = (slv_reg_wren && (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h0));

    assign start_pulse = (write_ctrl && S_AXI_WDATA[0]);

    assign start = start_pulse;
    assign tx_data = slv_reg1[7:0];

    assign cs_manual_en = slv_reg0[1];
    assign cs_n_manual = slv_reg0[2];


    

endmodule

