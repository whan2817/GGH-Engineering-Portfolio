`timescale 1ns / 1ps

class transaction;

    rand bit [7:0] rand_data;
    bit            rx;
    bit            tx;
    bit      [9:0] tx_reg;

    // Start bit와 구분할 수 있도록 전송 데이터에서 0을 제외한다.
    constraint rand_data_c {
        rand_data != 0; 
    }

    function debug_print(string name);
        $display("%0t : [%0s] rand_data = %0d expected_data = %0d", $time,
                 name, rand_data, tx_reg[8:1]);
    endfunction

endclass

interface uart_fifo_loopback_interface;

    logic clk;
    logic rst;
    logic rx;
    logic tx;

endinterface

class generator;

    transaction tr;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;

    event event_gen_next;

    function new(mailbox#(transaction) gen2drv_mbox,
                 mailbox#(transaction) gen2scb_mbox, event event_gen_next);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.gen2scb_mbox   = gen2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin
            tr= new();
            tr.randomize();
            tr.debug_print("GEN");
            gen2scb_mbox.put(tr);
            gen2drv_mbox.put(tr);
            
            @(event_gen_next);
        end

    endtask

endclass

class driver;

    transaction tr;
    parameter BAUD_PERIOD = ((100_000_000 / 9600) * 10);
    int i = 0;

    mailbox #(transaction) gen2drv_mbox;

    virtual uart_fifo_loopback_interface uart_fifo_vif;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual uart_fifo_loopback_interface uart_fifo_vif);
        this.gen2drv_mbox  = gen2drv_mbox;
        this.uart_fifo_vif = uart_fifo_vif;
    endfunction

    task presest();
        uart_fifo_vif.rst = 1;
        @(posedge uart_fifo_vif.clk);
        @(posedge uart_fifo_vif.clk);
        uart_fifo_vif.rst = 0;
        uart_fifo_vif.rx = 1;

        @(negedge uart_fifo_vif.clk);

        assert ((uart_fifo_vif.tx)) 
            $display(
                "========== [DRV Assert] ==========\n     RESET PASS :    TX   = 1 \n==================================\n\n"
            );
        else $display("[DRV Assert] reset fail : tx = %0d", uart_fifo_vif.tx);

    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.debug_print("DRV");
            @(posedge uart_fifo_vif.clk);
            #1;
            // Start bit 이후 8비트 데이터를 LSB부터 전송하고 Stop bit를 인가한다.
            uart_fifo_vif.rx = 0;
            #(BAUD_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                uart_fifo_vif.rx = tr.rand_data[i];
                #(BAUD_PERIOD);
            end
            uart_fifo_vif.rx = 1;
            #(BAUD_PERIOD);
        end
    endtask

endclass

class monitor;

    transaction tr;
    parameter BAUD_PERIOD = ((100_000_000 / 9600) * 10);
    int i = 0;

    mailbox #(transaction) mon2scb_mbox;
    virtual uart_fifo_loopback_interface uart_fifo_vif;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual uart_fifo_loopback_interface uart_fifo_vif);
        this.mon2scb_mbox  = mon2scb_mbox;
        this.uart_fifo_vif = uart_fifo_vif;
    endfunction

    task run();
        forever begin
            tr = new;

            // TX 하강 에지를 기준으로 각 비트의 중앙값을 수집한다.
            @(negedge uart_fifo_vif.tx);
            #(BAUD_PERIOD / 2);

            for (i = 0; i < 10; i = i + 1) begin
                
                tr.tx_reg[i] = uart_fifo_vif.tx;
                #(BAUD_PERIOD);
            end
            tr.debug_print("MON");
            mon2scb_mbox.put(tr);
        end
    endtask

endclass

class scoreboard;

    transaction tr1;
    transaction tr2;
    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event event_gen_next;

    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;

    function new(mailbox#(transaction) mon2scb_mbox,
                 mailbox#(transaction) gen2scb_mbox, event event_gen_next);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.gen2scb_mbox   = gen2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run();
        forever begin
            gen2scb_mbox.get(tr1);
            mon2scb_mbox.get(tr2);
            $display("%0t : [SCB] rand_data = %0d expected_data = %0d", $time,
                tr1.rand_data, tr2.tx_reg[8:1]);
            total_cnt++;
            if ((tr1.rand_data) == (tr2.tx_reg[8:1])) begin
                pass_cnt++;
                $display(
                        "======= [PASS !!] =======\n   TIME      : %0t\n   RX_DATA   = [%b]\n   TX_DATA   = [%b]\n=========================\n",
                        $time, tr1.rand_data, tr2.tx_reg[8:1]);
            end else begin
                fail_cnt++;
                $display("%0t : FAIL SEND DATA = %0d, RECIVE DATA = %0d",
                         $time, tr1.rand_data, tr2.tx_reg);
            end
            ->event_gen_next;
        end
    endtask

endclass

class environment;

    generator                            gen;
    driver                               drv;
    monitor                              mon;
    scoreboard                           scb;

    mailbox #(transaction)               gen2drv_mbox;
    mailbox #(transaction)               mon2scb_mbox;
    mailbox #(transaction)               gen2scb_mbox;
    event                                event_gen_next;
    virtual uart_fifo_loopback_interface uart_fifo_vif;

    function new(virtual uart_fifo_loopback_interface uart_fifo_vif);
        gen2drv_mbox = new;
        gen2scb_mbox = new;
        mon2scb_mbox = new;

        gen = new(gen2drv_mbox, gen2scb_mbox, event_gen_next);
        drv = new(gen2drv_mbox, uart_fifo_vif);
        mon = new(mon2scb_mbox, uart_fifo_vif);
        scb = new(mon2scb_mbox, gen2scb_mbox, event_gen_next);

        this.uart_fifo_vif = uart_fifo_vif;

    endfunction

    task run();

        drv.presest();

        fork
            gen.run(1);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        $display("UART_FIFO_LOOPBACK Constraint random test end");
        $display("========= UART_FIFO_LOOPBACK Verification ==========");
        $display("               total test num = %0d", scb.total_cnt);
        $display("               Pass  test num = %0d", scb.pass_cnt);
        $display("               Fail  test num = %0d", scb.fail_cnt);
        $display("====================================================");
        $stop;


    endtask

endclass


module tb_uart_fifo_loopback_sv ();

    uart_fifo_loopback_interface uart_fifo_if ();

    environment env;

    TOP U_UART_FIFO_LOOPBACK (
        .clk(uart_fifo_if.clk),
        .rst(uart_fifo_if.rst),
        .rx (uart_fifo_if.rx),
        .tx (uart_fifo_if.tx)
    );

    always #5 uart_fifo_if.clk = ~uart_fifo_if.clk;

    initial begin
        uart_fifo_if.clk = 0;
        env = new(uart_fifo_if);
        env.run();
    end

endmodule
