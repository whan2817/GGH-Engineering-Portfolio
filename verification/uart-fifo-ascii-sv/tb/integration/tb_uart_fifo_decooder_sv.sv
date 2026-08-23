`timescale 1ns / 1ps


class transaction;

    rand bit [7:0] rand_data; 
    bit rx;
    bit [5:0] button_sel;

    constraint UART_DATA_LIST{
        rand_data inside{
            8'h44,
            8'h4C,
            8'h4D,
            8'h52,
            8'h53,
            8'h55,
            8'h64,
            8'h6C,
            8'h6D,
            8'h72,
            8'h73,
            8'h75,
            8'hff   // 정의되지 않은 명령
        };
    }

    function debug_print1(string name);
        $display("%0t : [%0s] rand_data = %0c",
                 $time, name, rand_data);
    endfunction

    function debug_print2(string name);
        $display("%0t : [%0s] expected_data = %b",
                 $time, name, button_sel);
    endfunction


endclass


interface uart_fifo_decoder_interface;

    logic clk;
    logic rst;
    logic rx;
    logic [5:0] button_sel;
    logic rx_done;

endinterface

class generator;

    transaction tr;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;

    event event_gen_next;

    function new(mailbox #(transaction) gen2drv_mbox, mailbox #(transaction) gen2scb_mbox, event event_gen_next);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat(count) begin
            tr = new;
            tr.randomize();

            gen2drv_mbox.put(tr);           
            gen2scb_mbox.put(tr); 
            tr.debug_print1("GEN");
            @(event_gen_next);
        end
    endtask

endclass

class driver;

    transaction tr;
    parameter BAUD_PERIOD = ((100_000_000 / 9600) * 10);
    int i = 0;

    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;

    virtual uart_fifo_decoder_interface uart_fifo_decoder_vif;

    function new(mailbox #(transaction) gen2drv_mbox, virtual uart_fifo_decoder_interface uart_fifo_decoder_vif);
        this. gen2drv_mbox = gen2drv_mbox;
        this. uart_fifo_decoder_vif = uart_fifo_decoder_vif;
    endfunction

    task presest();
        uart_fifo_decoder_vif.rst = 1;
        @(posedge uart_fifo_decoder_vif.clk);
        @(posedge uart_fifo_decoder_vif.clk);
        uart_fifo_decoder_vif.rst = 0;
        @(posedge uart_fifo_decoder_vif.clk);
        
        uart_fifo_decoder_vif.rx = 1;


        @(negedge uart_fifo_decoder_vif.clk);

        assert (!(uart_fifo_decoder_vif.button_sel)) $display(
                "========== [DRV Assert] ==========\n  RESET PASS : BUTTON_SEL = 0 \n=================================="
            );
        else $display("[DRV Assert] reset fail : button_sel = %0d", uart_fifo_decoder_vif.button_sel);

    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.debug_print1("DRV");

            @(posedge uart_fifo_decoder_vif.clk);
            #1;
            // ASCII 명령을 UART Frame 형식으로 직렬화해 입력한다.
            uart_fifo_decoder_vif.rx = 0;
            #(BAUD_PERIOD);

            for (i = 0; i < 8; i = i + 1) begin
                uart_fifo_decoder_vif.rx = tr.rand_data[i];
                #(BAUD_PERIOD);
            end     
            uart_fifo_decoder_vif.rx = 1;
            #(BAUD_PERIOD);
        end
    endtask

endclass

class monitor;

    transaction tr;
    parameter BAUD_PERIOD = ((100_000_000 / 9600) * 10);
    int i = 0;

    mailbox #(transaction) mon2scb_mbox;

    virtual uart_fifo_decoder_interface uart_fifo_decoder_vif;

    function new(mailbox #(transaction) mon2scb_mbox, virtual uart_fifo_decoder_interface uart_fifo_decoder_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.uart_fifo_decoder_vif = uart_fifo_decoder_vif;
    endfunction

    task run();
        forever begin
            // UART 수신 완료 후 FIFO와 Decoder의 상태 전이가 끝난 시점에 출력값을 수집한다.
            @(posedge uart_fifo_decoder_vif.rx_done);
            repeat(3) @(posedge uart_fifo_decoder_vif.clk);
            @(negedge uart_fifo_decoder_vif.clk);
            
            tr = new;
            tr.button_sel = uart_fifo_decoder_vif.button_sel;
            mon2scb_mbox.put(tr);
            tr.debug_print2("MON");
        end
    endtask

endclass

class scoreboard;

    transaction tr1;
    transaction tr2;
    logic [5:0] expected_button_sel;

    event event_gen_next;

    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) gen2scb_mbox;

    function new(mailbox #(transaction) mon2scb_mbox, mailbox #(transaction) gen2scb_mbox, event event_gen_next);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run();
        forever begin
            gen2scb_mbox.get(tr1);
            // UART 입력 문자에 대응하는 one-hot 기대값을 생성한다.
            case (tr1.rand_data)
                8'h44:   expected_button_sel = 6'b000001;  //D
                8'h4C:   expected_button_sel = 6'b000010;  //L
                8'h4D:   expected_button_sel = 6'b000100;  //M
                8'h52:   expected_button_sel = 6'b001000;  //R
                8'h53:   expected_button_sel = 6'b010000;  //S
                8'h55:   expected_button_sel = 6'b100000;  //U
                8'h64:   expected_button_sel = 6'b000001;  //d
                8'h6C:   expected_button_sel = 6'b000010;  //l
                8'h6D:   expected_button_sel = 6'b000100;  //m
                8'h72:   expected_button_sel = 6'b001000;  //r
                8'h73:   expected_button_sel = 6'b010000;  //s
                8'h75:   expected_button_sel = 6'b100000;  //u
                default: expected_button_sel = 0;
            endcase

            mon2scb_mbox.get(tr2);
            tr2.debug_print2("SCB");
            
            total_cnt++;
            if (expected_button_sel == tr2.button_sel) begin
                pass_cnt++;
                $display("%0t : PASS !! uart_data = %0c, Expected Data = %b, Decoding Data = %b\n", $time, tr1.rand_data, expected_button_sel, tr2.button_sel);               
            end else begin
                fail_cnt++;
                $display("%0t : FAIL !! Expected Data = %0b, Decoding Data = %0b", $time, expected_button_sel, tr2.button_sel);
            end
            ->event_gen_next;
        end

    endtask

endclass


class environment;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    event event_gen_next;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;
    mailbox #(transaction) mon2scb_mbox;

    virtual uart_fifo_decoder_interface uart_fifo_decoder_vif;

    function new(virtual uart_fifo_decoder_interface uart_fifo_decoder_vif);
        gen2drv_mbox = new;
        gen2scb_mbox = new;
        mon2scb_mbox = new;

        gen = new(gen2drv_mbox, gen2scb_mbox, event_gen_next);
        drv = new(gen2drv_mbox, uart_fifo_decoder_vif);
        mon = new(mon2scb_mbox, uart_fifo_decoder_vif);
        scb = new(mon2scb_mbox, gen2scb_mbox, event_gen_next);

        this.uart_fifo_decoder_vif = uart_fifo_decoder_vif;

    endfunction

    task run();

        drv.presest();

        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
        
        #10;
        $display("UART_RX_FIFO_ASCII_DECODER Constraint random test end");
        $display("========= UART_RX_FIFO_ASCII_DECODER Verification ==========");
        $display("                  total test num = %0d", scb.total_cnt);
        $display("                  Pass  test num = %0d", scb.pass_cnt);
        $display("                  Fail  test num = %0d", scb.fail_cnt);
        $display("============================================================");
        $stop;

    

    endtask

endclass



module tb_uart_fifo_decooder_sv ();

    uart_fifo_decoder_interface uart_fifo_decoder_if();

    environment env;

    uart_fifo_decoder dut (

        .clk       (uart_fifo_decoder_if.clk),
        .rst       (uart_fifo_decoder_if.rst),
        .rx        (uart_fifo_decoder_if.rx),
        .button_sel(uart_fifo_decoder_if.button_sel)
    );

    assign uart_fifo_decoder_if.rx_done = dut.U_UART_RX.rx_done;

    always #5 uart_fifo_decoder_if.clk = ~uart_fifo_decoder_if.clk;

    initial begin
        uart_fifo_decoder_if.clk = 0;
        uart_fifo_decoder_if.rx = 1;
        env = new(uart_fifo_decoder_if);
        env.run();


    end


endmodule
