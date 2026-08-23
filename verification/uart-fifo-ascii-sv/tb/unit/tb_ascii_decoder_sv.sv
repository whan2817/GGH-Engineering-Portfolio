`timescale 1ns / 1ps

class transaction;

    bit            start;
    rand bit [7:0] UART_DATA;
    bit      [5:0] button_sel;

    typedef enum { UART_DATA_LIST, NON_UART_DATA_LIST } data_group_e;
    rand data_group_e data_group;

    constraint data_group_c {
        if (data_group == UART_DATA_LIST) {
            UART_DATA inside{
                8'h44, //D
                8'h4C, //L
                8'h4D, //M
                8'h52, //R
                8'h53, //S
                8'h55, //U
                8'h64, //d
                8'h6C, //l
                8'h6D, //m
                8'h72, //r
                8'h73, //s
                8'h75  //u
            };
        } else if (data_group == NON_UART_DATA_LIST) {
            UART_DATA inside{
                8'h41, //A
                8'h42, //B
                8'h43, //C
                8'h45, //E
                8'h46, //F
                8'h47, //G
                8'h61, //a
                8'h62, //b
                8'h63, //c
                8'h65, //e
                8'h66, //f
                8'h67  //g
            };
        }
    }

    constraint in_range {
        data_group dist {NON_UART_DATA_LIST:/100};
    }

    function debug_print1(string name);
        $display("%0t : [%0s] ASCII DATA = %c", $time,
                 name, UART_DATA);
    endfunction

    function debug_print2(string name);
        $display("%0t : [%0s] BUTTON_SEL DATA = %b", $time,
                 name, button_sel);
    endfunction

endclass

interface ascii_decoder_interface;

    logic  clk;
    logic  start;
    logic  rst;
    logic  [7:0] UART_DATA;
    logic  [5:0] button_sel;

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
        repeat (count) begin
            tr = new;
            tr.randomize();
            tr.debug_print1("GEN");
            gen2drv_mbox.put(tr);
            gen2scb_mbox.put(tr);
            @(event_gen_next);
        end
    endtask

endclass

class driver;

    transaction tr;

    mailbox #(transaction) gen2drv_mbox;

    virtual ascii_decoder_interface ascii_decoder_vif;

    function new(mailbox #(transaction) gen2drv_mbox, virtual ascii_decoder_interface ascii_decoder_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.ascii_decoder_vif = ascii_decoder_vif;
    endfunction

    task presest();
        ascii_decoder_vif.rst = 1;
        @(posedge ascii_decoder_vif.clk);
        @(posedge ascii_decoder_vif.clk);
        ascii_decoder_vif.rst = 0;
        ascii_decoder_vif.start = 0;

        @(negedge ascii_decoder_vif.clk);

        assert (!(ascii_decoder_vif.button_sel)) $display(
                "========== [DRV Assert] ==========\n  RESET PASS : BUTTON_SEL = 0 \n=================================="
            );
        else $display("[DRV Assert] reset fail : button_sel = %0d", ascii_decoder_vif.button_sel);

    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            tr.debug_print1("DRV");
            @(posedge ascii_decoder_vif.clk);
            #1;
            ascii_decoder_vif.start = 1'b1;
            ascii_decoder_vif.UART_DATA = tr.UART_DATA;
            @(posedge ascii_decoder_vif.clk);
            #1;
            ascii_decoder_vif.start = 1'b0;
        end
    endtask

endclass

class monitor;

    transaction tr;

    mailbox #(transaction) mon2scb_mbox;

    virtual ascii_decoder_interface ascii_decoder_vif;

    function new(mailbox #(transaction) mon2scb_mbox, virtual ascii_decoder_interface ascii_decoder_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.ascii_decoder_vif = ascii_decoder_vif;
    endfunction

    task run();
        forever begin
            // 상태 전이가 완료된 시점에 button_sel을 수집한다.
            @(posedge ascii_decoder_vif.start);
            @(posedge ascii_decoder_vif.clk);
            @(posedge ascii_decoder_vif.clk);
            @(negedge ascii_decoder_vif.clk); 
            tr = new;
            tr.button_sel = ascii_decoder_vif.button_sel;
            tr.debug_print2("MON");
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
    logic [5:0] expected_button_sel;

    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0, default_cnt = 0;

    function new(mailbox #(transaction) mon2scb_mbox, mailbox #(transaction) gen2scb_mbox, event event_gen_next);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run();
        forever begin
            gen2scb_mbox.get(tr1);
            // 입력 문자에 대응하는 one-hot 기대값을 생성한다.
            case (tr1.UART_DATA)
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
                if (expected_button_sel != 0) begin
                    pass_cnt++;
                    $display(
                            "\n========= [PASS !!] =========\n  CURRENT TIME   : [%0t us]\n    UART_DATA    =     %c\n  EXPECTED DATA  = [ %b ]\n BUTTON_SEL DATA = [ %b ]\n=============================\n",
                            $time, tr1.UART_DATA, expected_button_sel, tr2.button_sel);
                end else begin
                    default_cnt++;
                    $display(
                            "\n========= [DEFAULT] =========\n  CURRENT TIME   : [%0t us]\n Default Data [%c] is not in List\n=============================\n",
                            $time, tr1.UART_DATA);
                end
            end else begin
                fail_cnt++;
                $display("%0t : FAIL !! Expected Data = %0d, Decoding Data = %0d", $time, expected_button_sel, tr2.button_sel);
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

    virtual ascii_decoder_interface ascii_decoder_vif;

    function new(virtual ascii_decoder_interface ascii_decoder_vif);
        gen2drv_mbox = new;
        gen2scb_mbox = new;
        mon2scb_mbox = new;

        gen = new(gen2drv_mbox, gen2scb_mbox, event_gen_next);
        drv = new(gen2drv_mbox, ascii_decoder_vif);
        mon = new(mon2scb_mbox, ascii_decoder_vif);
        scb = new(mon2scb_mbox, gen2scb_mbox, event_gen_next);

        this.ascii_decoder_vif = ascii_decoder_vif;

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
        $display("ASCII_DECODER Constraint random test end");
        $display("========= ASCII_DECODER Verification ==========");
        $display("             total test num = %0d", scb.total_cnt);
        $display("             Pass  test num = %0d", scb.pass_cnt);
        $display("             Fail  test num = %0d", scb.fail_cnt);
        $display("          Default  test num = %0d", scb.default_cnt);
        $display("===============================================");
        $stop;

    
    endtask

endclass



module tb_ascii_decoder_sv ();

    ascii_decoder_interface ascii_decoder_if();

    environment env;

    ascii_decoder U_ASCII_DECODER (
        .clk       (ascii_decoder_if.clk),
        .start     (ascii_decoder_if.start),
        .rst       (ascii_decoder_if.rst),
        .UART_DATA (ascii_decoder_if.UART_DATA),
        .button_sel(ascii_decoder_if.button_sel)
    );

    always #5 ascii_decoder_if.clk = ~ascii_decoder_if.clk;

    initial begin
        ascii_decoder_if.clk = 0;
        env = new(ascii_decoder_if);
        env.run();
    end

endmodule
