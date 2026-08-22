// START, WRITE, READ, STOP 단위 동작을 조합해 I2C 트랜잭션 시나리오를 구성한다.
class i2c_base_seq extends uvm_sequence #(i2c_seq_item);

    `uvm_object_utils(i2c_base_seq)

    localparam bit [6:0] SLAVE_ADDR = 7'h20;

    function new(string name = "i2c_base_seq");
        super.new(name);
    endfunction

    task do_read_addr(input bit [7:0] slave_data);
    i2c_seq_item item;

    item = i2c_seq_item::type_id::create("item");
    start_item(item);

    item.cmd                = I2C_WRITE;
    item.role               = ROLE_ADDR;
    item.master_tx_data     = {SLAVE_ADDR, 1'b1};
    item.slave_tx_data      = slave_data;
    item.exp_master_rx_data = slave_data;
    item.exp_slave_rx_data  = 8'h00;

    finish_item(item);
    endtask


    task do_start();
        i2c_seq_item item;

        item = i2c_seq_item::type_id::create("item");
        start_item(item);

        item.cmd            = I2C_START;
        item.role           = ROLE_NONE;
        item.master_tx_data = 8'h00;
        item.slave_tx_data  = 8'h00;

        finish_item(item);
    endtask


    task do_write(input bit [7:0] data, input i2c_role_e role);

        i2c_seq_item item;

        item = i2c_seq_item::type_id::create("item");
        start_item(item);

        item.cmd = I2C_WRITE;
        item.role              = role;
        item.master_tx_data    = data;
        item.slave_tx_data = 8'h00;
        if (role == ROLE_DATA)
            item.exp_slave_rx_data = data;
        else item.exp_slave_rx_data = 8'h00;
        finish_item(item);
    endtask


    task do_read(input bit [7:0] slave_data);
        i2c_seq_item item;

        item = i2c_seq_item::type_id::create("item");
        start_item(item);

        item.cmd                = I2C_READ;
        item.role               = ROLE_DATA;
        item.master_tx_data     = 8'h00;
        item.slave_tx_data      = slave_data;
        item.exp_master_rx_data = slave_data;
        item.exp_slave_rx_data  = 8'h00;

        finish_item(item);
    endtask


    task do_stop();
        i2c_seq_item item;

        item = i2c_seq_item::type_id::create("item");
        start_item(item);

        item.cmd            = I2C_STOP;
        item.role           = ROLE_NONE;
        item.master_tx_data = 8'h00;
        item.slave_tx_data  = 8'h00;

        finish_item(item);
    endtask

endclass


class i2c_write_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_write_seq)

    rand bit [7:0] data;

    function new(string name = "i2c_write_seq");
        super.new(name);
    endfunction


    task body();
        `uvm_info(get_type_name(), "I2C Write 시나리오 시작...", UVM_LOW)

        data = $urandom_range(0, 255);

        do_start();


        do_write({SLAVE_ADDR, 1'b0},
                 ROLE_ADDR);


        do_write(data,
                 ROLE_DATA);

        do_stop();

        `uvm_info(get_type_name(), "I2C Write 시나리오 종료 --", UVM_LOW)

    endtask

endclass


class i2c_read_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_read_seq)

    rand bit [7:0] slave_data;

    function new(string name = "i2c_read_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "I2C Read 시나리오 시작...", UVM_LOW)

        slave_data = $urandom_range(0, 255);

        do_start();

        do_read_addr(slave_data);


        do_read(slave_data);

        do_stop();

        `uvm_info(get_type_name(), "I2C Read 시나리오 종료 --", UVM_LOW)

    endtask
endclass


class i2c_multi_write_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_multi_write_seq)

    rand int num;

    constraint c_num {
        num inside {[10 : 30]};
    }

    function new(string name = "i2c_multi_write_seq");
        super.new(name);
    endfunction

    task body();
        bit [7:0] data;

        `uvm_info(get_type_name(),
                  $sformatf("I2C Multi write 시나리오 시작.. (%0d byte)",
                            num), UVM_LOW)

        do_start();


        do_write({SLAVE_ADDR, 1'b0}, ROLE_ADDR);

        repeat (num) begin
            data = $urandom_range(0, 255);
            do_write(data, ROLE_DATA);
        end

        do_stop();

        `uvm_info(get_type_name(), "I2C Multi write 시나리오 종료 --",
                  UVM_LOW)
    endtask
endclass


class i2c_random_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_random_seq)

    rand int num;
    constraint c_num {num inside {[100 : 150]};}

    function new(string name = "i2c_random_seq");
        super.new(name);
    endfunction

    task body();
        bit [7:0] data;
        bit [7:0] slave_data;
        bit       rw;

        `uvm_info(get_type_name(),
                  $sformatf("i2c random 시나리오 시작 (%0d 반복)", num),
                  UVM_LOW)

        repeat (num) begin
            rw = $urandom_range(0, 1);

            if (rw == 1'b0) begin
                data = $urandom_range(0, 255);

                do_start();
                do_write({SLAVE_ADDR, 1'b0}, ROLE_ADDR);
                do_write(data, ROLE_DATA);
                do_stop();

                `uvm_info(get_type_name(),
                          $sformatf("WRITE data = %02h", data), UVM_LOW)
            end else begin
                slave_data = $urandom_range(0, 255);

                do_start();
                do_read_addr(slave_data);
                do_read(slave_data);
                do_stop();

                `uvm_info(get_type_name(), $sformatf(
                          "READ data = %02h", slave_data), UVM_LOW)
            end
        end
        `uvm_info(get_type_name(), "I2C random 시나리오 종료", UVM_LOW)
    endtask

endclass

class i2c_boundary_data_seq extends i2c_base_seq;
    `uvm_object_utils(i2c_boundary_data_seq)

    function new(string name = "i2c_boundary_data_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info(get_type_name(), "I2C Boundary Data 시나리오 시작...", UVM_LOW)


        do_start();
        do_write({SLAVE_ADDR, 1'b0}, ROLE_ADDR);
        do_write(8'h00, ROLE_DATA);
        do_stop();


        do_start();
        do_write({SLAVE_ADDR, 1'b0}, ROLE_ADDR);
        do_write(8'hFF, ROLE_DATA);
        do_stop();


        do_start();
        do_read_addr(8'h00);
        do_read(8'h00);
        do_stop();


        do_start();
        do_read_addr(8'hFF);
        do_read(8'hFF);
        do_stop();

        `uvm_info(get_type_name(), "I2C Boundary Data 시나리오 종료 --", UVM_LOW)
    endtask

endclass
