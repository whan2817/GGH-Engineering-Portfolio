module axi_master (
	input  logic        ACLK,
    input  logic        ARESETn,
    
    input  logic        transfer,
    output logic        ready,
    input  logic [4:0]  addr,
    input  logic [31:0] wdata,
    output logic [31:0] rdata,
    input  logic        write,
    
    output logic [4:0]  AWADDR,
    output logic        AWVALID,
    input  logic        AWREADY,
    
    output logic [31:0] WDATA,
    output logic        WVALID,
    input  logic        WREADY,
    
    input  logic [ 1:0] BRESP,
    input  logic        BVALID,
    output logic        BREADY,
    
    output logic [4:0]  ARADDR,
    output logic        ARVALID,
    input  logic        ARREADY,
    
    input  logic [31:0] RDATA,
    input  logic        RVALID,
    output logic        RREADY,
    input  logic [ 1:0] RRESP
);
    logic w_ready, r_ready;
    assign ready = w_ready | r_ready;

    
    
    typedef enum logic { AW_IDLE  = 0, AW_VALID } aw_state_e;
    aw_state_e aw_state, aw_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn)	aw_state <= AW_IDLE;
        else			aw_state <= aw_state_next;
    end

    always_comb begin
        aw_state_next = aw_state;
        AWADDR        = addr;
        AWVALID       = 1'b0;
        case (aw_state)
            AW_IDLE: begin AWVALID = 1'b0;
                if (transfer & write) aw_state_next = AW_VALID;
            end
            AW_VALID: begin AWADDR  = addr; AWVALID = 1'b1;
                if (AWREADY&AWVALID) aw_state_next = AW_IDLE;
            end
            default: begin
                AWADDR        = addr;
                AWVALID       = 1'b0;
                aw_state_next = AW_IDLE;
            end
        endcase
    end

    
    typedef enum logic { W_IDLE  = 0, W_VALID } w_state_e;
    w_state_e w_state, w_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn)	w_state <= W_IDLE;
        else			w_state <= w_state_next;
    end

    always_comb begin
        w_state_next = w_state;
        WDATA        = wdata;
        WVALID       = 1'b0;
        case (w_state)
            W_IDLE: begin WVALID = 1'b0;
                if (transfer & write) w_state_next = W_VALID;
            end
            W_VALID: begin WDATA  = wdata; WVALID = 1'b1;
                if (WREADY&WVALID) w_state_next = W_IDLE;
            end
            default: begin
                WDATA        = wdata;
                WVALID       = 1'b0;
                w_state_next = W_IDLE;
            end
        endcase
    end

    
    typedef enum logic { B_IDLE  = 0, B_READY } b_state_e;
    b_state_e b_state, b_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            b_state <= B_IDLE;
        end else begin
            b_state <= b_state_next;
        end
    end

    always_comb begin
        b_state_next = b_state;
        w_ready        = 1'b0;
        case (b_state)
			B_IDLE: begin
			    BREADY = 1'b0;
			    if (BVALID) begin
			        b_state_next = B_READY;
			    end
			end
			B_READY: begin
			    BREADY = 1'b1;
			    if (BVALID && BREADY) begin
			        b_state_next = B_IDLE;
			        w_ready = 1'b1;
			    end
			end
            default: begin
                BREADY       = 1'b0;
                b_state_next = B_IDLE;
            end
        endcase
    end

    
    
    typedef enum logic { AR_IDLE  = 0, AR_VALID } ar_state_e;
    ar_state_e ar_state, ar_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            ar_state <= AR_IDLE;
        end else begin
            ar_state <= ar_state_next;
        end
    end

    always_comb begin
        ar_state_next = ar_state;
        ARADDR        = addr;
        ARVALID       = 1'b0;
        case (ar_state)
            AR_IDLE: begin
                ARVALID = 1'b0;
                if (transfer & !write) begin
                    ar_state_next = AR_VALID;
                end
            end
            AR_VALID: begin
                ARADDR  = addr;
                ARVALID = 1'b1;
                if (ARREADY&ARVALID) begin
                    ar_state_next = AR_IDLE;
                end
            end
            default: begin
                ARADDR        = addr;
                ARVALID       = 1'b0;
                ar_state_next = AR_IDLE;
            end
        endcase
    end

    
    typedef enum logic { R_IDLE  = 0, R_READY } r_state_e;
    r_state_e r_state, r_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            r_state <= R_IDLE;
        end else begin
            r_state <= r_state_next;
        end
    end

    always_comb begin
        r_state_next = r_state;
        r_ready      = 1'b0;
        RREADY       = 1'b0;
        case (r_state)
            R_IDLE: begin
                RREADY = 1'b0;
                if (ARVALID&ARREADY) begin
                    r_state_next = R_READY;
                end
            end
            R_READY: begin
                RREADY = 1'b1;
                if (RVALID&RREADY) begin
                    r_state_next = R_IDLE;
                    rdata        = RDATA;
                    r_ready        = 1'b1;
                end
            end
            default: begin
                RREADY       = 1'b0;
                r_state_next = R_IDLE;
            end
        endcase
    end

endmodule

