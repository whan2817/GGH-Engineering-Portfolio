// 슬레이브 선택과 송수신 데이터를 묶어 기본, 랜덤, 경계값 시나리오를 구성한다.
class spi_sequence extends uvm_sequence#(spi_seq_item);
    `uvm_object_utils(spi_sequence)

    function new(string name = "spi_sequence");
        super.new(name);
    endfunction

    task do_slave0(bit [7:0] m_tx_data, bit [7:0] s0_tx_data);
        spi_seq_item item;
        item = spi_seq_item::type_id::create("item");
        start_item(item);
        item.slave_sel = 1'b0;
        item.m_tx_data = m_tx_data;
        item.s0_tx_data = s0_tx_data;
        item.cpol      = 1'b0;
        item.cpha      = 1'b0;
        item.clk_div   = 8'd9;
        finish_item(item);
    endtask

    task do_slave1(bit [7:0] m_tx_data, bit [7:0] s1_tx_data);
        spi_seq_item item;
        item = spi_seq_item::type_id::create("item");
        start_item(item);
        item.slave_sel = 1'b1;
        item.m_tx_data = m_tx_data;
        item.s1_tx_data = s1_tx_data;
        item.cpol      = 1'b0;
        item.cpha      = 1'b0;
        item.clk_div   = 8'd9;
        finish_item(item);
    endtask
endclass


class spi_basic_seq extends spi_sequence;
    `uvm_object_utils(spi_basic_seq)
    rand int num;
    constraint c_num { num inside {[5:20]}; }

    function new(string name = "spi_basic_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), $sformatf("기본 시나리오 시작 (%0d 반복 * slave 2개 = %0d번)", num, num*2), UVM_LOW)
        repeat(num) begin
            do_slave0($urandom_range(0,255), $urandom_range(0,255));
            do_slave1($urandom_range(0,255), $urandom_range(0,255));
        end
        `uvm_info(get_type_name(), "기본 시나리오 종료", UVM_LOW)
    endtask
endclass


class spi_random_seq extends spi_sequence;
    `uvm_object_utils(spi_random_seq)
    rand int num;
    constraint c_num { num inside {[30:100]}; }

    function new(string name = "spi_random_seq");
        super.new(name);
    endfunction

    task body();
        spi_seq_item item;
        `uvm_info(get_type_name(), $sformatf("랜덤 시나리오 시작 (%0d 반복)", num), UVM_LOW)
        repeat(num) begin
            item = spi_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_error("SEQ", "randomize 실패")
            finish_item(item);
        end
        `uvm_info(get_type_name(), "랜덤 시나리오 종료", UVM_LOW)
    endtask
endclass


class spi_corner_seq extends spi_sequence;
    `uvm_object_utils(spi_corner_seq)

    function new(string name = "spi_corner_seq");
        super.new(name);
    endfunction

    task body();
        bit [7:0] corner_vals[$] = {8'h00, 8'hff, 8'h55, 8'haa};

        `uvm_info(get_type_name(), $sformatf("경계값 시나리오 시작 (%0d 반복 * slave 2개 = %0d번)",
              corner_vals.size(), corner_vals.size() * 2), UVM_LOW)
        foreach(corner_vals[i]) begin
            do_slave0(corner_vals[i], corner_vals[i]);
            do_slave1(corner_vals[i], corner_vals[i]);
        end
        `uvm_info(get_type_name(), "경계값 시나리오 종료", UVM_LOW)
    endtask
endclass
