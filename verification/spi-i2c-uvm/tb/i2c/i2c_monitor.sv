class i2c_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_monitor)

    virtual i2c_if i2c_if;

    uvm_analysis_port #(i2c_seq_item) ip;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ip = new("ip", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "i2c_if", i2c_if))
            `uvm_fatal(get_type_name(),
                       "virtual interface(i2c_if)를 config_db에서 찾을 수 없습니다.")
    endfunction

    task run_phase(uvm_phase phase);
        i2c_seq_item item;
        bit addr_phase;

        // 명령 흐름에서 주소와 데이터를 구분해 스코어보드용 트랜잭션으로 재구성한다.
        addr_phase = 1'b0;

        @(i2c_if.mon_cb);

        forever begin
            @(i2c_if.mon_cb);

            item = null;

            if (i2c_if.mon_cb.cmd_start) begin
                item = i2c_seq_item::type_id::create("item");

                item.cmd = I2C_START;
                item.role = ROLE_NONE;
                item.master_tx_data = 8'h00;
                item.slave_tx_data  = 8'h00;

                addr_phase = 1'b1;

                wait_master_done();

                item.master_rx_data = i2c_if.mon_cb.master_rx_data;
                item.slave_rx_data  = i2c_if.mon_cb.slave_rx_data;

                `uvm_info(get_type_name(), $sformatf("%s", item.convert2string()), UVM_HIGH)

                ip.write(item);
            end else if (i2c_if.mon_cb.cmd_write) begin
                item = i2c_seq_item::type_id::create("item");

                item.cmd = I2C_WRITE;
                item.master_tx_data = i2c_if.mon_cb.master_tx_data;
                item.slave_tx_data  = 8'h00;

                if (addr_phase) begin
                    item.role = ROLE_ADDR;
                    addr_phase = 1'b0;
                end else begin
                    item.role = ROLE_DATA;
                end

                wait_master_done();

                item.master_tx_data = i2c_if.mon_cb.master_tx_data;
                item.exp_slave_rx_data = item.master_tx_data;
                item.slave_rx_data  = i2c_if.mon_cb.slave_rx_data;

                `uvm_info(get_type_name(),
                              $sformatf("%s", item.convert2string()),
                              UVM_HIGH)

                ip.write(item);
            end else if (i2c_if.mon_cb.cmd_read) begin
                    item = i2c_seq_item::type_id::create("item");

                    item.cmd            = I2C_READ;
                    item.role           = ROLE_DATA;
                    item.master_tx_data = 8'h00;
                    item.slave_tx_data  = i2c_if.mon_cb.slave_tx_data;

                    wait_master_done();

                    item.master_rx_data = i2c_if.mon_cb.master_rx_data;
                    item.exp_master_rx_data = item.slave_tx_data;
                    item.slave_rx_data  = i2c_if.mon_cb.slave_rx_data;

                    `uvm_info(get_type_name(),
                              $sformatf("%s", item.convert2string()),
                              UVM_HIGH)

                    ip.write(item);
            end else if (i2c_if.mon_cb.cmd_stop) begin
                    item = i2c_seq_item::type_id::create("item");

                    item.cmd            = I2C_STOP;
                    item.role           = ROLE_NONE;
                    item.master_tx_data = 8'h00;
                    item.slave_tx_data  = 8'h00;

                    addr_phase = 1'b0;

                    wait_master_done();

                    item.master_rx_data = i2c_if.mon_cb.master_rx_data;
                    item.slave_rx_data  = i2c_if.mon_cb.slave_rx_data;

                    `uvm_info(get_type_name(),
                              $sformatf("%s", item.convert2string()),
                              UVM_HIGH)

                    ip.write(item);
            end
        end
    endtask

    task wait_master_done();
        int timeout_cnt;

        timeout_cnt = 0;

        while (i2c_if.mon_cb.master_done !== 1'b1) begin
            @(i2c_if.mon_cb);

            timeout_cnt = timeout_cnt + 1;

            if (timeout_cnt > 20000) begin
                `uvm_error(get_type_name(), "master_done timeout!!")
                return;
            end
        end

        @(i2c_if.mon_cb);
    endtask


endclass
