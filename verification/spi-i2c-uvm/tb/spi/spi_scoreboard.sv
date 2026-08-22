class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)
    uvm_analysis_imp#(spi_seq_item, spi_scoreboard) imp;

    int tx_pass_count = 0;
    int tx_fail_count = 0;
    int rx_pass_count = 0;
    int rx_fail_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    // 선택된 슬레이브를 기준으로 Master-Slave 양방향 전송 결과를 각각 비교한다.
    function void write(spi_seq_item tr);

        if (tr.slave_sel == 1'b0) begin
            if (tr.m_tx_data === tr.s0_rx_data) begin
                tx_pass_count++;
                `uvm_info(get_type_name(), $sformatf(
                    "TX PASS [master->slave0]: m_tx=0x%02h s0_rx=0x%02h",
                    tr.m_tx_data, tr.s0_rx_data), UVM_MEDIUM)
            end else begin
                tx_fail_count++;
                `uvm_error(get_type_name(), $sformatf(
                    "TX FAIL [master->slave0]: m_tx=0x%02h s0_rx=0x%02h (기대값=0x%02h)",
                    tr.m_tx_data, tr.s0_rx_data, tr.m_tx_data))
            end
        end else begin
            if (tr.m_tx_data === tr.s1_rx_data) begin
                tx_pass_count++;
                `uvm_info(get_type_name(), $sformatf(
                    "TX PASS [master->slave1]: m_tx=0x%02h s1_rx=0x%02h",
                    tr.m_tx_data, tr.s1_rx_data), UVM_MEDIUM)
            end else begin
                tx_fail_count++;
                `uvm_error(get_type_name(), $sformatf(
                    "TX FAIL [master->slave1]: m_tx=0x%02h s1_rx=0x%02h (기대값=0x%02h)",
                    tr.m_tx_data, tr.s1_rx_data, tr.m_tx_data))
            end
        end


        if (tr.slave_sel == 1'b0) begin
            if (tr.s0_tx_data === tr.m_rx_data) begin
                rx_pass_count++;
                `uvm_info(get_type_name(), $sformatf(
                    "RX PASS[slave0->master]: s0_tx=0x%02h m_rx=0x%02h",
                    tr.s0_tx_data, tr.m_rx_data), UVM_MEDIUM)
            end else begin
                rx_fail_count++;
                `uvm_error(get_type_name(), $sformatf(
                    "RX FAIL[slave0->master]: s0_tx=0x%02h m_rx=0x%02h (기대값=0x%02h)",
                    tr.s0_tx_data, tr.m_rx_data, tr.s0_tx_data))
            end
        end else begin

            if (tr.s1_tx_data === tr.m_rx_data) begin
                rx_pass_count++;
                `uvm_info(get_type_name(), $sformatf(
                    "RX PASS[slave1->master]: s1_tx=0x%02h m_rx=0x%02h",
                    tr.s1_tx_data, tr.m_rx_data), UVM_MEDIUM)
            end else begin
                rx_fail_count++;
                `uvm_error(get_type_name(), $sformatf(
                    "RX FAIL[slave1->master]: s1_tx=0x%02h m_rx=0x%02h (기대값=0x%02h)",
                    tr.s1_tx_data, tr.m_rx_data, tr.s1_tx_data))
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", "================================", UVM_LOW)
        `uvm_info("SCB", "=======Scoreboard Summary=======", UVM_LOW)
        `uvm_info("SCB", "================================", UVM_LOW)
        `uvm_info("SCB", "    master TX -> slave RX    ", UVM_LOW)
        `uvm_info("SCB", $sformatf("pass count: %0d", tx_pass_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("fail count: %0d", tx_fail_count), UVM_LOW)
        `uvm_info("SCB", "================================", UVM_LOW)
        `uvm_info("SCB", "    slave TX -> master RX    ", UVM_LOW)
        `uvm_info("SCB", $sformatf("pass count: %0d", rx_pass_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("fail count: %0d", rx_fail_count), UVM_LOW)
        `uvm_info("SCB", "================================", UVM_LOW)


        if (tx_fail_count > 0 || rx_fail_count > 0) begin
            `uvm_error(get_type_name(), $sformatf(
                "TEST FAILED: TX fail=%0d, RX fail=%0d",
                tx_fail_count, rx_fail_count))
        end else begin
            `uvm_info(get_type_name(), $sformatf(
                "TEST PASSED: TX pass=%0d, RX pass=%0d",
                tx_pass_count, rx_pass_count), UVM_LOW)
        end
    endfunction
endclass
