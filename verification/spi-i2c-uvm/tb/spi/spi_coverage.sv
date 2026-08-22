class spi_coverage extends uvm_subscriber#(spi_seq_item);
    `uvm_component_utils(spi_coverage)
    spi_seq_item tr;

    // 슬레이브 선택, 데이터 구간, 양방향 일치 여부의 기능 커버리지를 수집한다.
    covergroup spi_cg;
        option.per_instance = 1;

        cp_slave : coverpoint tr.slave_sel {
            bins slave0 = {1'b0};
            bins slave1 = {1'b1};
        }

        cp_m_tx : coverpoint tr.m_tx_data {
            bins data_zero = {8'h00};
            bins data_max  = {8'hff};
            bins data_low1  = {[8'h01 : 8'h3f]};
            bins data_low2  = {[8'h40 : 8'h7f]};
            bins data_high1 = {[8'h80 : 8'hbf]};
            bins data_high2 = {[8'hc0 : 8'hfe]};
        }

        cp_s0_tx : coverpoint tr.s0_tx_data iff(tr.slave_sel == 1'b0) {
            bins data_zero = {8'h00};
            bins data_max  = {8'hff};
            bins data_low  = {[8'h01 : 8'h7f]};
            bins data_high = {[8'h80 : 8'hfe]};
        }

        cp_s1_tx : coverpoint tr.s1_tx_data iff(tr.slave_sel == 1'b1) {
            bins data_zero = {8'h00};
            bins data_max  = {8'hff};
            bins data_low  = {[8'h01 : 8'h7f]};
            bins data_high = {[8'h80 : 8'hfe]};
        }
        cp_tx_match : coverpoint (tr.m_tx_data ===
                                 (tr.slave_sel ? tr.s1_rx_data : tr.s0_rx_data)) {
            bins match    = {1'b1};

        }

        cp_rx_match_0 : coverpoint (tr.s0_tx_data === tr.m_rx_data) {
            bins match    = {1'b1};

        }

        cp_rx_match_1 : coverpoint (tr.s1_tx_data === tr.m_rx_data) {
            bins match    = {1'b1};

        }

        cx_slave_tx       : cross cp_slave, cp_m_tx;


    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        spi_cg = new();
    endfunction

    function void write(spi_seq_item t);
        tr = t;
        spi_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV", "=================================", UVM_LOW)
        `uvm_info("COV", "=======Functional Coverage=======", UVM_LOW)
        `uvm_info("COV", "=================================", UVM_LOW)
        `uvm_info("COV", $sformatf("전체                   : %6.2f %%", spi_cg.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("슬레이브 선택          : %6.2f %%", spi_cg.cp_slave.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("TX 데이터              : %6.2f %%", spi_cg.cp_m_tx.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("RX 데이터              : %6.2f %%", spi_cg.cp_s0_tx.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("RX 데이터              : %6.2f %%", spi_cg.cp_s1_tx.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("Master TX -> Slave RX  : %6.2f %%", spi_cg.cp_tx_match.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("Slave0 TX -> Master RX : %6.2f %%", spi_cg.cp_rx_match_0.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("Slave1 TX -> Master RX : %6.2f %%", spi_cg.cp_rx_match_1.get_inst_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf("SlavexTX               : %6.2f %%", spi_cg.cx_slave_tx.get_inst_coverage()), UVM_LOW)


        `uvm_info("COV", "=================================", UVM_LOW)

        if (spi_cg.get_inst_coverage() < 100.0)
            `uvm_warning("COV", "커버리지 100% 미달! 시나리오를 추가하세요")
    endfunction
endclass
