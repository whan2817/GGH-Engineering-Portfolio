class i2c_driver extends uvm_driver #(i2c_seq_item);
    `uvm_component_utils(i2c_driver)

    virtual i2c_if i2c_if;

    function new(string name = "i2c_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "i2c_if", i2c_if))
            `uvm_fatal(get_type_name(),
                       "i2c_if를 config_db에서 찾을 수 없습니다")
    endfunction

    task preset();
        i2c_if.drv_cb.rst <= 1'b1;

        i2c_if.drv_cb.cmd_start <= 1'b0;
        i2c_if.drv_cb.cmd_write <= 1'b0;
        i2c_if.drv_cb.cmd_read <= 1'b0;
        i2c_if.drv_cb.cmd_stop <= 1'b0;

        i2c_if.drv_cb.master_tx_data <= 8'h00;
        i2c_if.drv_cb.slave_tx_data <= 8'h00;

        repeat (5) @(i2c_if.drv_cb);

        i2c_if.drv_cb.rst <= 1'b0;

        repeat (5) @(i2c_if.drv_cb);
    endtask

    task clear_cmd();
        i2c_if.drv_cb.cmd_start <= 1'b0;
        i2c_if.drv_cb.cmd_write <= 1'b0;
        i2c_if.drv_cb.cmd_read  <= 1'b0;
        i2c_if.drv_cb.cmd_stop  <= 1'b0;
    endtask

    task wait_master_done();

        while (i2c_if.drv_cb.master_done !== 1'b1) begin
            @(i2c_if.drv_cb);
        end

        @(i2c_if.drv_cb);

    endtask

    task drive_start();
        clear_cmd();

        i2c_if.drv_cb.cmd_start <= 1'b1;
        @(i2c_if.drv_cb);
        i2c_if.drv_cb.cmd_start <= 1'b0;

        wait_master_done();
    endtask

    task drive_write(input i2c_seq_item item);
        clear_cmd();

        i2c_if.drv_cb.master_tx_data <= item.master_tx_data;


        if (item.role == ROLE_ADDR && item.master_tx_data[0] == 1'b1) begin
            i2c_if.drv_cb.slave_tx_data <= item.slave_tx_data;
        end

        i2c_if.drv_cb.cmd_write <= 1'b1;
        @(i2c_if.drv_cb);
        i2c_if.drv_cb.cmd_write <= 1'b0;

        wait_master_done();
    endtask

    task drive_read(input bit [7:0] slave_data);
        clear_cmd();

        i2c_if.drv_cb.slave_tx_data <= slave_data;

        i2c_if.drv_cb.cmd_read <= 1'b1;
        @(i2c_if.drv_cb);
        i2c_if.drv_cb.cmd_read <= 1'b0;

        wait_master_done();
    endtask

    task drive_stop();
        clear_cmd();

        i2c_if.drv_cb.cmd_stop <= 1'b1;
        @(i2c_if.drv_cb);
        i2c_if.drv_cb.cmd_stop <= 1'b0;

        wait_master_done();
    endtask


    // 시퀀스 명령을 한 클럭 펄스로 변환하고 master_done까지 각 단계를 동기화한다.
    task drive_item(i2c_seq_item item);
        case (item.cmd)
            I2C_START: begin
                drive_start();
            end
            I2C_WRITE: begin
                drive_write(item);
            end
            I2C_READ: begin
                drive_read(item.slave_tx_data);
            end
            I2C_STOP: begin
                drive_stop();
            end
            default:
            `uvm_error("DRV", "정의되지 않은 I2C Command입니다.")
        endcase
    endtask

    task run_phase(uvm_phase phase);
        i2c_seq_item item;

        preset();

        forever begin
            seq_item_port.get_next_item(item);

            drive_item(item);

            seq_item_port.item_done();
        end
    endtask

endclass
