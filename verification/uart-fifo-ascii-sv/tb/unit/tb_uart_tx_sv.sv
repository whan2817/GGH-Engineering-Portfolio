`timescale 1ns / 1ps `timescale 1ns / 1ps

class transaction;

    bit            tx_start;
    rand bit [7:0] tx_data;
    bit            ib_tick;
    bit            tx_busy;
    bit            tx;
    bit      [9:0] tx_reg;

    function debug_print(string name);
        $display(
            "%0t : [%0s] tx_start = %0d, tx_data = %0d, tx_busy = %0d, tx = %0d",
            $time, name, tx_start, tx_data, tx_busy, tx);
    endfunction


endclass

interface uart_tx_interface;

    logic       clk;
    logic       rst;
    logic       tx_start;
    logic [7:0] tx_data;
    logic       ib_tick;
    logic       tx_busy;
    logic       tx;

endinterface

class generator;

    transaction tr;
    event event_gen_next;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;

    function new(mailbox#(transaction) gen2drv_mbox,
                 mailbox#(transaction) gen2scb_mbox, event event_gen_next);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.gen2scb_mbox   = gen2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin
            tr = new();
            tr.randomize();
            $display("==================================================");
            $display(" [%0t] [GENERATE RAND_DATA] : [%b]", $time, tr.tx_data);
            $display("==================================================\n\n");
            gen2drv_mbox.put(tr);
            gen2scb_mbox.put(tr);
            tr.debug_print("GEN");
            @(event_gen_next);
        end
    endtask

endclass

class driver;

    transaction tr;
    parameter BAUD_PERIOD = ((100_000_000 / 9600) * 10);
    int i = 0;


    mailbox #(transaction) gen2drv_mbox;
    virtual uart_tx_interface tx_vif;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual uart_tx_interface tx_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.tx_vif = tx_vif;
    endfunction

    task presest();
        tx_vif.rst = 1;
        @(posedge tx_vif.clk);
        @(posedge tx_vif.clk);
        tx_vif.rst = 0;

        @(negedge tx_vif.clk);
        // Reset 이후 TX 출력과 Busy 신호의 초기 상태를 확인한다.
        assert (!(tx_vif.tx_busy))
            $display(
                "========== [DRV Assert] ==========\n     RESET PASS : TX_BUSY = 0 \n=================================="
            );
        else
            $display("[DRV Assert] reset fail : tx_busy = %0d", tx_vif.tx_busy);

        assert ((tx_vif.tx))
            $display(
                "========== [DRV Assert] ==========\n     RESET PASS :    TX   = 1 \n==================================\n\n"
            );
        else $display("[DRV Assert] reset fail : tx = %0d", tx_vif.tx);

    endtask


    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.debug_print("DRV");
            @(posedge tx_vif.clk);
            #1;
            tx_vif.tx_start = 1'b1;
            tx_vif.tx_data  = tr.tx_data;
            @(posedge tx_vif.clk);
            #1;
            tx_vif.tx_start = 1'b0;
        end
    endtask



endclass

class monitor;

    transaction tr;

    parameter BAUD_PERIOD = ((100_000_000 / 9600) * 10);

    int i = 0;

    mailbox #(transaction) mon2scb_mbox;
    virtual uart_tx_interface tx_vif;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual uart_tx_interface tx_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.tx_vif = tx_vif;
    endfunction

    task run();
        forever begin
            @(posedge tx_vif.tx_start);
            tr = new;
            tr.tx_start = tx_vif.tx_start;
            tr.tx_busy = tx_vif.tx_busy;
            if (tr.tx_busy) begin
                $display(
                    "\n========== [* WARNING *] ==========\n       TX IS RUNNING NOW !!! \n===================================");
            end else begin
                tr.tx_data = tx_vif.tx_data;
                tr.debug_print("MON");

                // TX 하강 에지를 UART Frame의 Start bit로 감지한다.
                @(negedge tx_vif.tx);

                // 각 비트의 중앙에서 값을 수집하도록 반 주기만큼 이동한다.
                #(BAUD_PERIOD / 2);

                for (i = 0; i < 10; i = i + 1) begin
                    tr.tx_reg[i] = tx_vif.tx;
                    $display("%t, tx_reg[%0d] = %b", $time, i, tr.tx_reg[i]);
                    #(BAUD_PERIOD);
                end
                mon2scb_mbox.put(tr);
            end
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
            tr2.debug_print("SCB");
            $display("\n");
            total_cnt++;
            // 송신 입력과 Monitor가 직렬 Frame에서 복원한 데이터를 비교한다.
            if ((!tr2.tx_busy)) begin
                if ((tr1.tx_data) == (tr2.tx_reg[8:1])) begin
                    pass_cnt++;
                    $display(
                        "======= [PASS !!] =======\n   TIME      : %0t\n   TX_DATA   = [%b]\n TX_REG[8:1] = [%b]\n=========================\n",
                        $time, tr1.tx_data, tr2.tx_reg[8:1]);
                end else begin
                    fail_cnt++;
                    $display(
                        "%0t : FAIL tx_start = %0d, tx_data = %0d, tx_busy = %0d, tx = %0d",
                        $time, tr1.tx_start, tr1.tx_data, tr1.tx_busy, tr1.tx);
                end
            end
            ->event_gen_next;
        end
    endtask



endclass

class environment;

    generator                 gen;
    driver                    drv;
    monitor                   mon;
    scoreboard                scb;

    mailbox #(transaction)    gen2drv_mbox;
    mailbox #(transaction)    mon2scb_mbox;
    mailbox #(transaction)    gen2scb_mbox;
    event                     event_gen_next;
    virtual uart_tx_interface tx_vif;

    function new(virtual uart_tx_interface tx_vif);
        gen2drv_mbox = new;
        gen2scb_mbox = new;
        mon2scb_mbox = new;

        gen = new(gen2drv_mbox, gen2scb_mbox, event_gen_next);
        drv = new(gen2drv_mbox, tx_vif);
        mon = new(mon2scb_mbox, tx_vif);
        scb = new(mon2scb_mbox, gen2scb_mbox, event_gen_next);

        this.tx_vif = tx_vif;

    endfunction

    task run();
        drv.presest();

        fork
            gen.run(100);
            drv.run();
            mon.run();
            scb.run();
        join_any

        #10;
        $display("UART_TX Constraint random test end");
        $display("========= UART_TX Verification ==========");
        $display("          total test num = %0d", scb.total_cnt);
        $display("          Pass  test num = %0d", scb.pass_cnt);
        $display("          Fail  test num = %0d", scb.fail_cnt);
        $display("=========================================");
        $stop;


    endtask



endclass


module tb_uart_tx_sv ();

    uart_tx_interface tx_if ();

    environment env;



    baud_tick_gen dut2 (
        .clk     (tx_if.clk),
        .rst     (tx_if.rst),
        .o_b_tick(tx_if.ib_tick)
    );


    uart_tx dut (
        .clk     (tx_if.clk),
        .rst     (tx_if.rst),
        .tx_start(tx_if.tx_start),
        .tx_data (tx_if.tx_data),
        .ib_tick (tx_if.ib_tick),
        .tx_busy (tx_if.tx_busy),
        .tx      (tx_if.tx)
    );



    always #5 tx_if.clk = ~tx_if.clk;

    initial begin
        tx_if.clk = 0;
        env       = new(tx_if);
        env.run();
    end


endmodule
