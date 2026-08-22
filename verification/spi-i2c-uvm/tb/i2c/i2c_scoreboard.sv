class i2c_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(i2c_scoreboard)
    uvm_analysis_imp #(i2c_seq_item, i2c_scoreboard) imp;

    int write_pass = 0;
    int write_fail = 0;
    int read_pass = 0;
    int read_fail = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    // 데이터 단계만 선별해 Write 수신값과 Read 반환값을 기대값과 비교한다.
    function void write(i2c_seq_item item);
        if (item.role == ROLE_DATA) begin
            if (item.cmd == I2C_WRITE) begin
                if (item.exp_slave_rx_data === item.slave_rx_data) begin
                    write_pass++;
                    `uvm_info(get_type_name(),
                              $sformatf("WRITE PASS: m_tx=0x%02h s_rx=0x%02h",
                                        item.exp_slave_rx_data,
                                        item.slave_rx_data), UVM_MEDIUM)
                end else begin
                    write_fail++;
                    `uvm_error(get_type_name(), $sformatf(
                               "WRITE FAIL: m_tx=0x%02h s_rx=0x%02h",
                               item.exp_slave_rx_data,
                               item.slave_rx_data
                               ))
                end
            end else if (item.cmd == I2C_READ) begin
                if (item.exp_master_rx_data === item.master_rx_data) begin
                    read_pass++;
                    `uvm_info(get_type_name(),
                              $sformatf("READ PASS: s_tx=0x%02h m_rx=0x%02h",
                                        item.exp_master_rx_data,
                                        item.master_rx_data), UVM_MEDIUM)
                end else begin
                    read_fail++;
                    `uvm_error(get_type_name(), $sformatf(
                               "READ FAIL: s_tx=0x%02h m_rx=0x%02h",
                               item.exp_master_rx_data,
                               item.master_rx_data
                               ))
                end
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", "================================", UVM_LOW)
        `uvm_info("SCB", "=======Scoreboard Summary=======", UVM_LOW)
        `uvm_info("SCB", "================================", UVM_LOW)
        `uvm_info("SCB", "    Master WRITE -> Slave RX    ", UVM_LOW)
        `uvm_info("SCB", $sformatf("pass: %0d", write_pass), UVM_LOW)
        `uvm_info("SCB", $sformatf("fail: %0d", write_fail), UVM_LOW)
        `uvm_info("SCB", "================================", UVM_LOW)
        `uvm_info("SCB", "    Slave TX -> Master READ     ", UVM_LOW)
        `uvm_info("SCB", $sformatf("pass: %0d", read_pass), UVM_LOW)
        `uvm_info("SCB", $sformatf("fail: %0d", read_fail), UVM_LOW)
        `uvm_info("SCB", "================================", UVM_LOW)

        if (write_fail > 0 || read_fail > 0)
            `uvm_error(get_type_name(), $sformatf(
                       "TEST FAILED: write_fail=%0d read_fail=%0d",
                       write_fail,
                       read_fail
                       ))
        else
            `uvm_info(get_type_name(), $sformatf(
                      "TEST PASSED: write_pass=%0d read_pass=%0d",
                      write_pass,
                      read_pass
                      ), UVM_LOW)
    endfunction
endclass
