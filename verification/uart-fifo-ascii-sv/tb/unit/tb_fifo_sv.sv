`timescale 1ns / 1ps

class transaction;
    rand bit       push;
    rand bit [7:0] push_data;
    rand bit       pop;
    bit      [7:0] pop_data;
    bit            full;
    bit            empty;

    function debug_print1(string name);
        $display(
            "%0d : [%0s] push = %0d, pop = %0d, push_data = %0d",
            $time, name, push, pop, push_data);
    endfunction

    function debug_print2(string name);
        $display(
            "%0d : [%0s] push = %0d, pop = %0d, push_data = %0d, pop_data = %0d, full = %0d, empty = %0d",
            $time, name, push, pop, push_data, pop_data, full, empty);
    endfunction

endclass

interface fifo_interface;
    logic       clk;
    logic       rst;
    logic [7:0] push_data;
    logic       push;
    logic       pop;
    logic [7:0] pop_data;
    logic       full;
    logic       empty;
endinterface

class generator;
    transaction tr;

    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;

    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin
            tr = new;

            assert (tr.randomize())
            else $error("[GEN] tr.randomize() error!");

            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.debug_print1("GEN");
            @(event_gen_next);
        end
    endtask

endclass

class driver;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;
    virtual fifo_interface fifo_vif;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual fifo_interface fifo_vif, event event_gen_next);
        this.gen2drv_mbox = gen2drv_mbox;
        this.fifo_vif = fifo_vif;
        this.event_gen_next = event_gen_next;
    endfunction

    task presest();
        fifo_vif.rst = 1;

        @(posedge fifo_vif.clk);
        @(posedge fifo_vif.clk);
        fifo_vif.rst = 0;

        @(negedge fifo_vif.clk);

        // Reset 이후 FIFO의 Empty와 Full 초기 상태를 확인한다.
        assert (fifo_vif.empty)
            $display(
                "========== [DRV Assert] ==========\n     RESET PASS :  EMPTY  = 1 \n=================================="
            );
        else $display("[DRV Assert] reset fail : empty = %0d", fifo_vif.empty);

        assert (!fifo_vif.full)
            $display(
                "========== [DRV Assert] ==========\n     RESET PASS :   FULL  = 0 \n==================================\n\n"
            );
        else $display("[DRV Assert] reset fail : full = %0d", fifo_vif.full);

    endtask

    task push_only(int count);
        $display(
            "===================================\n      * FIFO PUSH Only Test *     \n===================================");
        repeat (count) begin
            gen2drv_mbox.get(tr);
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push      = 1;
            fifo_vif.push_data = tr.push_data;
            fifo_vif.pop       = 0;
            $display(
                "%0t : [DRV] push = %0d, pop = %0d, push_data = %0d, full = %0d, empty = %0d",
                $time, fifo_vif.push, fifo_vif.pop, fifo_vif.push_data,
                fifo_vif.full, fifo_vif.empty);
            ->event_gen_next;
        end
    endtask

    task pop_only(int count);
        $display("FIFO POP Only Test");
        repeat (count) begin
            gen2drv_mbox.get(tr);
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push = 0;
            fifo_vif.pop  = 1;
            $display(
                "%0t : [DRV] push = %0d, pop = %0d, push_data = %0d, full = %0d, empty = %0d",
                $time, fifo_vif.push, fifo_vif.pop, fifo_vif.push_data,
                fifo_vif.full, fifo_vif.empty);
            ->event_gen_next;
        end
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.debug_print1("DRV");
            @(posedge fifo_vif.clk);
            #1;
            fifo_vif.push_data  = tr.push_data;
            fifo_vif.push   = tr.push;
            fifo_vif.pop    = tr.pop;
        end
    endtask


endclass

class monitor;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual fifo_interface fifo_vif;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual fifo_interface fifo_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fifo_vif = fifo_vif;
    endfunction

    task run();
        forever begin
            @(negedge fifo_vif.clk);
            tr           = new;
            tr.push      = fifo_vif.push;
            tr.push_data = fifo_vif.push_data;
            tr.pop       = fifo_vif.pop;
            tr.pop_data  = fifo_vif.pop_data;
            tr.full      = fifo_vif.full;
            tr.empty     = fifo_vif.empty;
            mon2scb_mbox.put(tr);
            tr.debug_print2("MON");
        end
    endtask

endclass

class scoreboard;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event event_gen_next;
    int total_cnt = 0, push_cnt = 0, pop_cnt = 0, pass_cnt = 0, fail_cnt = 0;
    int full_cnt = 0, empty_cnt = 0, push_on_full_cnt = 0, pop_on_empty_cnt = 0;
    logic [7:0] fifo_Que[$:15];
    logic [7:0] mem_pop;

    function new(mailbox#(transaction) mon2scb_mbox, event event_gen_next);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.debug_print2("SCB");
            total_cnt++;
            
            // FIFO 상태와 각 입력 조합의 발생 횟수를 집계한다.
            if (tr.full) full_cnt++;
            if (tr.empty) empty_cnt++;
            if (tr.push) push_cnt++;
            if (tr.pop) pop_cnt++;

            if (tr.push && tr.full) push_on_full_cnt++;
            if (tr.pop && tr.empty) pop_on_empty_cnt++;
            

            // Queue를 참조 모델로 사용해 유효한 Pop 데이터 순서를 비교한다.
            if (tr.push && (!tr.full)) begin
                fifo_Que.push_front(tr.push_data);
            end
            if (tr.pop && (!tr.empty)) begin
                mem_pop = fifo_Que.pop_back();
                if (tr.pop_data == mem_pop) begin
                    pass_cnt++;
                    $display("%0d\n[    POP_DATA   ] = %b\n[ EXPECTED DATA ] = %b\nPASS !!!\n", $time, tr.pop_data, mem_pop);
                end else begin
                    fail_cnt++;
                    $display(
                        "%0t : FAIL pop = %0d, pop_data = %0d, compare data = %0d",
                        $time, tr.pop, tr.pop_data, mem_pop);
                end
            end
            ->event_gen_next;
        end
    endtask

endclass

class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;
    virtual fifo_interface fifo_vif;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event                  event_gen_next;
    int                    run_count;

    function new(virtual fifo_interface fifo_vif);
        gen2drv_mbox = new;
        mon2scb_mbox = new;

        gen = new(gen2drv_mbox, event_gen_next);
        drv = new(gen2drv_mbox, fifo_vif, event_gen_next);
        mon = new(mon2scb_mbox, fifo_vif);
        scb = new(mon2scb_mbox, event_gen_next);

        this.fifo_vif = fifo_vif;

    endfunction

    task run();
        drv.presest();

        // 무작위 Push와 Pop 조합을 반복해 데이터 순서와 경계 상태를 검증한다.
        fork
            gen.run(9999);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        $display("\n=== FIFO Constraint  Random Test End ===");
        $display("======== [ FIFO Verification ] =========");
        $display("       | total test num | = %0d ", scb.total_cnt);
        $display("       | push count num | = %0d ", scb.push_cnt);
        $display("       | pop  count num | = %0d ", scb.pop_cnt);
        $display("       | Full  occurred | = %0d ", scb.full_cnt);
        $display("       | Empty occurred | = %0d ", scb.empty_cnt);
        $display("       |  Push on Full  | = %0d ", scb.push_on_full_cnt);
        $display("       |  Pop on Empty  | = %0d ", scb.pop_on_empty_cnt);
        $display("       | Pass  test num | = %0d ", scb.pass_cnt);
        $display("       | Fail  test num | = %0d ", scb.fail_cnt);
        $display("========================================");
        $stop;
    endtask

endclass

module tb_fifo_sv ();

    fifo_interface fifo_if ();

    environment env;

    fifo dut (
        .clk      (fifo_if.clk),
        .rst      (fifo_if.rst),
        .push_data(fifo_if.push_data),
        .push     (fifo_if.push),
        .pop      (fifo_if.pop),
        .pop_data (fifo_if.pop_data),
        .full     (fifo_if.full),
        .empty    (fifo_if.empty)
    );


    always #5 fifo_if.clk = ~fifo_if.clk;

    initial begin
        fifo_if.clk = 0;
        env         = new(fifo_if);
        env.run();
    end

endmodule
