`timescale 1ns / 1ps

class transaction;
    bit            b_tick;
    bit            rx;
    rand bit [7:0] rand_data;
    bit      [7:0] rx_data;
    bit            rx_done;

    function debug_print(string name);
        $display("%0t : [%0s] rand_data = %0d, rx_data = %0d, rx_done = %0d",
                 $time, name, rand_data, rx_data, rx_done);
    endfunction


endclass


interface uart_rx_interface;

    logic       clk;
    logic       rst;
    logic       b_tick;
    logic       rx;
    logic [7:0] rx_data;
    logic       rx_done;

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
            $display(" [%0t] [GENERATE RAND_DATA] : [%b]", $time, tr.rand_data);
            gen2drv_mbox.put(tr);
            $display("==================================================\n\n");
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
    virtual uart_rx_interface rx_vif;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual uart_rx_interface rx_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.rx_vif = rx_vif;
    endfunction

    task presest();
        rx_vif.rst = 1;
        @(posedge rx_vif.clk);
        @(posedge rx_vif.clk);
        rx_vif.rst = 0;
        rx_vif.rx  = 1;

        @(negedge rx_vif.clk);
        // Reset 이후 수신 데이터와 완료 신호의 초기값을 확인한다.
        assert (!(rx_vif.rx_data))
            $display(
                "========== [DRV Assert] ==========\n     RESET PASS : RX_DATA = 0 \n=================================="
            );
        else $display("[DRV Assert] reset fail : empty = %0d", rx_vif.rx_data);

        assert (!(rx_vif.rx_done))
            $display(
                "========== [DRV Assert] ==========\n     RESET PASS : RX_DONE = 0 \n==================================\n\n"
            );
        else $display("[DRV Assert] reset fail : full = %0d", rx_vif.rx_done);



    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.debug_print("DRV");
            // Start bit 이후 8비트 데이터를 LSB부터 전송하고 Stop bit를 인가한다.
            rx_vif.rx = 0;
            #(BAUD_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                rx_vif.rx = tr.rand_data[i];
                #(BAUD_PERIOD);
            end
            rx_vif.rx = 1;
            #(BAUD_PERIOD);
        end
    endtask

endclass

class monitor;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual uart_rx_interface rx_vif;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual uart_rx_interface rx_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.rx_vif = rx_vif;
    endfunction

    task run();
        forever begin
            // rx_done 발생 시 복원된 병렬 데이터를 수집한다.
            @(posedge rx_vif.rx_done);
            tr = new;
            tr.rx_done = rx_vif.rx_done;
            tr.rx_data = rx_vif.rx_data;
            mon2scb_mbox.put(tr);
            tr.debug_print("MON");
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
            mon2scb_mbox.get(tr1);
            gen2scb_mbox.get(tr2);
            tr1.debug_print("SCB");
            $display("\n");
            total_cnt++;
            // 입력 데이터와 UART RX가 복원한 데이터를 비교한다.
            if (tr1.rx_done) begin
                if (tr1.rx_data == tr2.rand_data) begin
                    pass_cnt++;
                    $display("====== [PASS !!] ======\n TIME : %0t\n RAND_DATA = [%b]\n RX_DATA   = [%b]\n=======================\n", $time, tr2.rand_data, tr1.rx_data);
                end else begin
                    fail_cnt++;
                    $display(
                        "%0t : FAIL rand_data = %0d, rx_data = %0d, rx_done = %0d",
                        $time, tr2.rand_data, tr1.rx_data, tr1.rx_done);
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
    virtual uart_rx_interface rx_vif;

    function new(virtual uart_rx_interface rx_vif);
        gen2drv_mbox = new;
        gen2scb_mbox = new;
        mon2scb_mbox = new;

        gen = new(gen2drv_mbox, gen2scb_mbox, event_gen_next);
        drv = new(gen2drv_mbox, rx_vif);
        mon = new(mon2scb_mbox, rx_vif);
        scb = new(mon2scb_mbox, gen2scb_mbox, event_gen_next);

        this.rx_vif = rx_vif;

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
        $display("UART_RX Constraint random test end");
        $display("========= [UART_RX Verification] ==========");
        $display("           total test num = %0d", scb.total_cnt);
        $display("           Pass  test num = %0d", scb.pass_cnt);
        $display("           Fail  test num = %0d", scb.fail_cnt);
        $display("===========================================");
        $stop;


    endtask



endclass


module tb_uart_rx_sv ();

    uart_rx_interface rx_if ();

    environment env;



    baud_tick_gen dut2 (
        .clk     (rx_if.clk),
        .rst     (rx_if.rst),
        .o_b_tick(rx_if.b_tick)
    );

    uart_rx dut (
        .clk    (rx_if.clk),
        .rst    (rx_if.rst),
        .b_tick (rx_if.b_tick),
        .rx     (rx_if.rx),
        .rx_data(rx_if.rx_data),
        .rx_done(rx_if.rx_done)
    );



    always #5 rx_if.clk = ~rx_if.clk;

    initial begin
        rx_if.clk = 0;
        env       = new(rx_if);
        env.run();
    end


endmodule
