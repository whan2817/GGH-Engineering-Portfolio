module i2c_master_board (
    input logic clk,
    input logic rst,
    input logic i_write,  
    input logic i_read,
	input logic [15:0] tx_wdata,
	input logic [6:0] target_addr,
    output logic m_tx_done,
    output logic m_rx_done,
    output logic [7:0] m_rx_data,
    output logic scl,
    output logic sda_o,
    input  logic sda_i
);
	logic m_cmd_start, m_cmd_write, m_cmd_read, m_cmd_stop;
    logic [7:0] m_tx_data;
    logic m_done, m_busy;
    logic is_idle, is_addr_phase, is_data_phase;

	logic [7:0] SLA_W, SLA_R;
    assign SLA_W = {target_addr, 1'b0};  
    assign SLA_R = {target_addr, 1'b1};  
    
	i2c_demo U_DEMO_CTRL (
        .clk          (clk),
        .rst          (rst),
        .w_btn_write  (i_write),
        .w_btn_read   (i_read),
        .SLA_W        (SLA_W),
        .SLA_R        (SLA_R),
        .tx_wdata   (tx_wdata),
        .m_done       (m_done),
        .m_busy       (m_busy),
        .m_cmd_start  (m_cmd_start),
        .m_cmd_write  (m_cmd_write),
        .m_cmd_read   (m_cmd_read),
        .m_cmd_stop   (m_cmd_stop),
        .m_tx_data    (m_tx_data),
        .is_idle      (is_idle),
        .is_addr_phase(is_addr_phase),
        .is_data_phase(is_data_phase)
    );

    i2c_master_top U_MASTER (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(m_cmd_start),
        .cmd_write(m_cmd_write),
        .cmd_read (m_cmd_read),
        .cmd_stop (m_cmd_stop),
        .tx_data  (m_tx_data),
        .ack_in   (1'b1),
        .rx_data  (m_rx_data),
        .ack_out  (),
        .busy     (m_busy),
        .done     (m_done),
        .tx_done  (m_tx_done),
        .rx_done  (m_rx_done),
        .sda_o(sda_o),
        .scl(scl),
        .sda_i(sda_i)
    );
endmodule


// 상위 상태기는 START, 주소, 데이터, STOP 명령을 순서대로 생성한다.
module i2c_demo (
    input logic clk,
    input logic rst,

    input logic w_btn_write,
    input logic w_btn_read,

    input logic [7:0] SLA_W,
    input logic [7:0] SLA_R,
    input logic [15:0] tx_wdata,

    input logic m_done,
    input logic m_busy,

    output logic       m_cmd_start,
    output logic       m_cmd_write,
    output logic       m_cmd_read,
    output logic       m_cmd_stop,
    output logic [7:0] m_tx_data,

    
    output logic is_idle,       
    output logic is_addr_phase, 
    output logic is_data_phase  
);

    typedef enum logic [3:0] {
        IDLE,
        W_START,
        W_ADDR,
        W_DATA0,
        W_DATA1,
        W_DATA2,
        W_DATA3,
        W_STOP,
        R_START,
        R_ADDR,
        R_DATA,
        R_STOP
    } state_e;
    state_e state;

    assign is_idle       = (state == IDLE);
    assign is_addr_phase = (state == W_ADDR) || (state == R_ADDR);
    assign is_data_phase = (state == W_DATA0)||(state == W_DATA1)||
							(state == W_DATA2)||(state == W_DATA3);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            m_cmd_start <= 1'b0;
            m_cmd_write <= 1'b0;
            m_cmd_read  <= 1'b0;
            m_cmd_stop  <= 1'b0;
            m_tx_data   <= 8'h00;
        end else begin
            m_cmd_start <= 1'b0;
            m_cmd_write <= 1'b0;
            m_cmd_read  <= 1'b0;
            m_cmd_stop  <= 1'b0;
            case (state)
                IDLE: begin
                    if (w_btn_write) begin
                        m_cmd_start <= 1'b1;
                        state       <= W_START;
                    end else if (w_btn_read) begin
                        m_cmd_start <= 1'b1;
                        state       <= R_START;
                    end
                end
                
                W_START:
                if (m_done) begin
                    m_tx_data   <= SLA_W;
                    m_cmd_write <= 1'b1;
                    state       <= W_ADDR;
                end
                W_ADDR:
                if (m_done) begin
                    m_tx_data   <= {tx_wdata[15:12],tx_wdata[7:4]};
                    m_cmd_write <= 1'b1;
                    state       <= W_DATA0;
                end
                W_DATA0:
                if (m_done) begin
                    m_tx_data   <= {tx_wdata[15:12],tx_wdata[3:0]};
                    m_cmd_write <= 1'b1;
                    state       <= W_DATA1;
                end
                W_DATA1:
                if (m_done) begin
                    m_tx_data   <= {tx_wdata[11:8],tx_wdata[7:4]};
                    m_cmd_write <= 1'b1;
                    state       <= W_DATA2;
                end
                W_DATA2:
                if (m_done) begin
                    m_tx_data   <= {tx_wdata[11:8],tx_wdata[3:0]};
                    m_cmd_write <= 1'b1;
                    state       <= W_DATA3;
                end
                W_DATA3:
                if (m_done) begin
                    m_cmd_stop <= 1'b1;
                    state      <= W_STOP;
                end
                W_STOP:
                if (!m_busy) begin
                    state <= IDLE;
                end
                
                
                R_START:
                if (m_done) begin
                    m_tx_data   <= SLA_R;
                    m_cmd_write <= 1'b1;
                    state       <= R_ADDR;
                end
                R_ADDR:
                if (m_done) begin
                    m_cmd_read <= 1'b1;
                    state      <= R_DATA;
                end
                R_DATA:
                if (m_done) begin
                    m_cmd_stop <= 1'b1;
                    state      <= R_STOP;
                end
                R_STOP:
                if (!m_busy) begin
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule


module i2c_master_top (
    input logic clk,
    input logic rst,

    input logic cmd_start,
    input logic cmd_write,
    input logic cmd_read,
    input logic cmd_stop,

    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    input  logic       ack_in,
    output logic       ack_out,
    output logic       busy,
    output logic       done,

    output logic tx_done,
    output logic rx_done,

    output logic scl,
    output logic sda_o,
    input  logic sda_i
);
    typedef enum logic [2:0] {
        IDLE     = 3'b000,
        START,
        WAIT_CMD,
        DATA,
        DATA_ACK,
        STOP
    } i2c_state_e;
    i2c_state_e       state;

    logic       [7:0] div_cnt;
    logic             qtr_tick;
    logic             scl_r;
    logic             sda_r;
    logic       [1:0] step;
    logic       [7:0] tx_shift_reg;
    logic       [7:0] rx_shift_reg;
    logic       [2:0] bit_cnt;
    logic             is_read;
    logic             ack_in_r;

    assign scl   = scl_r;
    assign sda_o = sda_r;
    assign busy  = (state != IDLE);

    
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            div_cnt  <= 0;
            qtr_tick <= 1'b0;
        end else begin
            if (div_cnt == 250 - 1) begin
                div_cnt  <= 0;
                qtr_tick <= 1'b1;
            end else begin
                div_cnt  <= div_cnt + 1;
                qtr_tick <= 1'b0;
            end
        end
    end
    

    // 시스템 클럭을 분주해 I2C 한 비트를 네 구간으로 제어한다.
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            scl_r        <= 1'b1;
            sda_r        <= 1'b1;
            step         <= 2'd0;
            done         <= 1'b0;
            tx_done      <= 1'b0;
            rx_done      <= 1'b0;
            tx_shift_reg <= 8'h00;
            rx_shift_reg <= 8'h00;
            is_read      <= 1'b0;
            bit_cnt      <= 3'd0;
            ack_in_r     <= 1'b1;
            ack_out      <= 1'b1;
            rx_data      <= 8'h00;
        end else begin
            done    <= 1'b0;
            tx_done <= 1'b0;
            rx_done <= 1'b0;
            case (state)
                IDLE: begin
                    scl_r <= 1'b1;
                    sda_r <= 1'b1;
                    if (cmd_start) begin
                        state <= START;
                        step  <= 2'd0;
                    end
                end
                START: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd1;
                            end
                            2'd1: begin  
                                sda_r <= 1'b0;
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin  
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd3;
                            end
                            2'd3: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end

                WAIT_CMD: begin
                    if (cmd_write) begin
                        tx_shift_reg <= tx_data;
                        bit_cnt      <= 3'd0;
                        is_read      <= 1'b0;
                        state        <= DATA;
                    end 
                    else if (cmd_read) begin
                        rx_shift_reg <= 8'h00;
                        bit_cnt      <= 3'd0;
                        is_read      <= 1'b1;
                        ack_in_r     <= ack_in;
                        state        <= DATA;
                    end 
                    else if (cmd_stop) begin
                        state <= STOP;
                    end 
                    else if (cmd_start) begin
                        step  <= 2'd0;
                        state <= START;
                    end
                end

                DATA: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                sda_r <= is_read ? 1'b1 : tx_shift_reg[7];
                                
                                
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;  
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;  
                                step  <= 2'd3;
                                if (is_read)
                                    rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                if (!is_read) begin
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};  
                                end
                                step <= 2'd0;
                                if (bit_cnt == 3'd7) begin  
                                    state <= DATA_ACK;
                                end else begin  
                                    bit_cnt <= bit_cnt + 1;
                                end
                            end
                        endcase
                    end
                end

                DATA_ACK: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                sda_r <= is_read ? ack_in_r : 1'b1;
                                
                                
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;
                                step  <= 2'd3;
                                if (!is_read) ack_out <= sda_i;  
                                else rx_data <= rx_shift_reg;  
                            end
                            2'd3: begin
                                scl_r   <= 1'b0;
                                done    <= 1'b1;
                                tx_done <= !is_read;
                                rx_done <= is_read;
                                step    <= 2'd0;
                                state   <= WAIT_CMD;
                            end
                        endcase
                    end
                end

                STOP: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b1;  
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                sda_r <= 1'b1;  
                                scl_r <= 1'b1;
                                step  <= 2'd3;
                            end
                            2'd3: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd0;
                                state <= IDLE;
                            end
                        endcase
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
