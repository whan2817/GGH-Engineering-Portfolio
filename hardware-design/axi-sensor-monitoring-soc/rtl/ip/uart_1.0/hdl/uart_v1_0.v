`timescale 1 ns / 1 ps

	module uart_v1_0 #
	(
		

		
		


		
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		
		output wire tx,
		input  wire rx,
		output wire intr,
		
		

		
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);

		wire [7:0]          tx_data;
    	wire                tx_valid;
    	wire                tx_ready;
    	wire [7:0]          rx_data;
    	wire                rx_valid;
    	wire                rx_ie;
        wire                rx_irq;
    

		assign intr = rx_irq;

	  uart_v1_0_S00_AXI uart_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
		.tx_data(tx_data),
    	.tx_valid(tx_valid),
    	.tx_ready(tx_ready),
    	.rx_data(rx_data),
    	.rx_valid(rx_valid),
    	.rx_ie(rx_ie),
        .rx_irq(rx_irq)
	);

	
	uart_top u_uart(
    	.clk     (s00_axi_aclk),
    	.rst_n   (s00_axi_aresetn),
    	.tx_data (tx_data),
    	.tx_valid(tx_valid),
    	.tx_ready(tx_ready),
    	.tx		 (tx),
    	.rx		 (rx),
    	.rx_data (rx_data),
    	.rx_valid(rx_valid)
	);
	

	endmodule


module uart_top #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  wire       clk,
    input  wire       rst_n,
    
    input  wire [7:0] tx_data,
    input  wire       tx_valid,
    output wire       tx_ready,
    output wire       tx,
    
    input  wire       rx,
    output wire [7:0] rx_data,
    output wire       rx_valid
);

    uart_tx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_tx (
        .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (tx_data),
        .valid    (tx_valid),
        .ready    (tx_ready),
        .tx       (tx)
    );

    uart_rx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_rx (
        .clk      (clk),
        .rst_n    (rst_n),
        .rx       (rx),
        .data_out (rx_data),
        .valid    (rx_valid)
    );

endmodule


// RX는 보드레이트 기준 중앙 샘플링으로 시작 비트와 8비트 데이터를 수신한다.
module uart_rx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,         
    output reg  [7:0] data_out,   
    output reg        valid       
);

    localparam CLKS_PER_BIT  = CLK_FREQ / BAUD_RATE;
    localparam HALF_BIT      = CLKS_PER_BIT / 2;

    
    localparam S_IDLE  = 2'd0; 
    localparam S_START = 2'd1; 
    localparam S_DATA  = 2'd2; 
    localparam S_STOP  = 2'd3; 

    reg [1:0]                    state;
    reg [$clog2(CLKS_PER_BIT):0] clk_cnt;
    reg [2:0]                    bit_idx;
    reg [7:0]                    shift_reg;

    
    reg rx_sync0, rx_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync0 <= 1'b1;
            rx_sync  <= 1'b1;
        end else begin
            rx_sync0 <= rx;
            rx_sync  <= rx_sync0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            clk_cnt   <= 0;
            bit_idx   <= 0;
            shift_reg <= 8'h00;
            data_out  <= 8'h00;
            valid     <= 1'b0;
        end else begin
            valid <= 1'b0; 

            case (state)
                S_IDLE: begin
                    clk_cnt <= 0;
                    bit_idx <= 0;
                    if (rx_sync == 1'b0) 
                        state <= S_START;
                end

                
                S_START: begin
                    if (clk_cnt == HALF_BIT - 1) begin
                        clk_cnt <= 0;
                        if (rx_sync == 1'b0) 
                            state <= S_DATA;
                        else
                            state <= S_IDLE; 
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                
                S_DATA: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt              <= 0;
                        shift_reg[bit_idx]   <= rx_sync; 
                        if (bit_idx == 3'd7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                
                S_STOP: begin
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt  <= 0;
                        data_out <= shift_reg;
                        valid    <= 1'b1; 
                        state    <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule


// TX는 시작 비트, 8비트 데이터, 정지 비트를 순서대로 출력한다.
module uart_tx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115_200
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data_in,   
    input  wire       valid,     
    output reg        ready,     
    output reg        tx         
);

    
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    
    localparam S_IDLE  = 2'd0; 
    localparam S_START = 2'd1; 
    localparam S_DATA  = 2'd2; 
    localparam S_STOP  = 2'd3; 

    reg [1:0]                    state;
    reg [$clog2(CLKS_PER_BIT):0] clk_cnt;   
    reg [2:0]                    bit_idx;   
    reg [7:0]                    shift_reg; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            clk_cnt   <= 0;
            bit_idx   <= 0;
            shift_reg <= 8'h00;
            tx        <= 1'b1; 
            ready     <= 1'b1;
        end else begin
            case (state)
                S_IDLE: begin
                    tx    <= 1'b1;
                    ready <= 1'b1;
                    if (valid) begin
                        
                        shift_reg <= data_in;
                        clk_cnt   <= 0;
                        ready     <= 1'b0;
                        state     <= S_START;
                    end
                end

                S_START: begin
                    tx <= 1'b0; 
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        bit_idx <= 0;
                        state   <= S_DATA;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_DATA: begin
                    tx <= shift_reg[bit_idx]; 
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        if (bit_idx == 3'd7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                S_STOP: begin
                    tx <= 1'b1; 
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt <= 0;
                        state   <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
