module spi_eeprom_emulator (
    input  wire        clk,       
    input  wire        rst,       

    input  wire        sclk,      
    input  wire        mosi,      
    output wire        miso,      
    input  wire        cs_n,      

    output reg  [7:0]  last_cmd,
    output reg  [7:0]  last_addr,
    output reg  [7:0]  last_data,
    output wire [1:0]  dbg_state
);

    


    localparam [7:0] CMD_WRITE = 8'h02;
    localparam [7:0] CMD_READ  = 8'h03;

    


    localparam [1:0] ST_CMD   = 2'd0;
    localparam [1:0] ST_ADDR  = 2'd1;
    localparam [1:0] ST_WRITE = 2'd2;
    localparam [1:0] ST_READ  = 2'd3;

    reg [1:0] state;

    


    reg [7:0] mem [0:255];

    


    reg [2:0] bit_cnt;
    reg [7:0] rx_shift;
    reg [7:0] tx_shift;
    reg [7:0] read_data_buf;
    reg [7:0] addr_reg;
    reg       miso_reg;
    reg sclk_meta, sclk_sync, sclk_prev;
    reg mosi_meta, mosi_sync;
    reg cs_meta,   cs_sync,   cs_prev;

    wire [7:0] rx_byte_next;

    assign rx_byte_next = {rx_shift[6:0], mosi_sync};

    


    assign miso = (cs_n) ? 1'bz : miso_reg;

    assign dbg_state = state;

    


    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = i[7:0];
        end
    end

    


    wire sclk_rise;
    wire sclk_fall;
    wire cs_active;
    wire cs_rise;

    // 외부 SPI 신호를 시스템 클럭에 동기화해 상승과 하강 에지를 검출한다.
    always @(posedge clk) begin
        if (rst) begin
            sclk_meta <= 1'b0;
            sclk_sync <= 1'b0;
            sclk_prev <= 1'b0;

            mosi_meta <= 1'b0;
            mosi_sync <= 1'b0;

            cs_meta   <= 1'b1;
            cs_sync   <= 1'b1;
            cs_prev   <= 1'b1;
        end else begin
            sclk_meta <= sclk;
            sclk_sync <= sclk_meta;
            sclk_prev <= sclk_sync;

            mosi_meta <= mosi;
            mosi_sync <= mosi_meta;

            cs_meta   <= cs_n;
            cs_sync   <= cs_meta;
            cs_prev   <= cs_sync;
        end
    end

    assign sclk_rise = (sclk_sync == 1'b1) && (sclk_prev == 1'b0);
    assign sclk_fall = (sclk_sync == 1'b0) && (sclk_prev == 1'b1);
    assign cs_active = (cs_sync == 1'b0);
    assign cs_rise   = (cs_sync == 1'b1) && (cs_prev == 1'b0);

    


    always @(posedge clk) begin
        if (rst) begin
            state         <= ST_CMD;
            bit_cnt       <= 3'd0;
            rx_shift      <= 8'd0;
            tx_shift      <= 8'd0;
            read_data_buf <= 8'd0;
            addr_reg      <= 8'd0;
            miso_reg      <= 1'b0;

            last_cmd      <= 8'd0;
            last_addr     <= 8'd0;
            last_data     <= 8'd0;
        end else begin

            


            if (cs_rise) begin
                state    <= ST_CMD;
                bit_cnt  <= 3'd0;
                rx_shift <= 8'd0;
                tx_shift <= 8'd0;
                miso_reg <= 1'b0;
            end

            


            else if (cs_active) begin

                


                if (sclk_rise) begin
                    if (bit_cnt == 3'd7) begin
                        


            // 명령, 주소, 데이터 단계를 구분해 순차 읽기와 쓰기를 처리한다.
                        case (state)
                            ST_CMD: begin
                                last_cmd <= rx_byte_next;

                                if (rx_byte_next == CMD_WRITE) begin
                                    state <= ST_ADDR;
                                end else if (rx_byte_next == CMD_READ) begin
                                    state <= ST_ADDR;
                                end else begin
                                    state <= ST_CMD;
                                end

                                bit_cnt  <= 3'd0;
                                rx_shift <= 8'd0;
                            end

                            ST_ADDR: begin
                                addr_reg  <= rx_byte_next;
                                last_addr <= rx_byte_next;

                                if (last_cmd == CMD_WRITE) begin
                                    state <= ST_WRITE;
                                end else if (last_cmd == CMD_READ) begin
                                    read_data_buf <= mem[rx_byte_next];
                                    last_data     <= mem[rx_byte_next];
                                    state         <= ST_READ;
                                end else begin
                                    state <= ST_CMD;
                                end

                                bit_cnt  <= 3'd0;
                                rx_shift <= 8'd0;
                            end

                            ST_WRITE: begin
                                


                                mem[addr_reg] <= rx_byte_next;

                                last_addr <= addr_reg;
                                last_data <= rx_byte_next;

                                addr_reg <= addr_reg + 8'd1;
                                state    <= ST_WRITE;

                                bit_cnt  <= 3'd0;
                                rx_shift <= 8'd0;
                            end

                            ST_READ: begin
                                


                                last_addr <= addr_reg;
                                last_data <= read_data_buf;

                                addr_reg      <= addr_reg + 8'd1;
                                read_data_buf <= mem[addr_reg + 8'd1];

                                state    <= ST_READ;
                                bit_cnt  <= 3'd0;
                                rx_shift <= 8'd0;
                            end

                            default: begin
                                state    <= ST_CMD;
                                bit_cnt  <= 3'd0;
                                rx_shift <= 8'd0;
                            end
                        endcase
                    end else begin
                        rx_shift <= rx_byte_next;
                        bit_cnt  <= bit_cnt + 3'd1;
                    end
                end

                


                if (sclk_fall) begin
                    if (state == ST_READ) begin
                        if (bit_cnt == 3'd0) begin
                            miso_reg <= read_data_buf[7];
                            tx_shift <= {read_data_buf[6:0], 1'b0};
                        end else begin
                            miso_reg <= tx_shift[7];
                            tx_shift <= {tx_shift[6:0], 1'b0};
                        end
                    end else begin
                        miso_reg <= 1'b0;
                        tx_shift <= 8'd0;
                    end
                end
            end

            


            else begin
                miso_reg <= 1'b0;
            end
        end
    end

endmodule
