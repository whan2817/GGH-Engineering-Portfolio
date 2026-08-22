class i2c_coverage extends uvm_subscriber #(i2c_seq_item);
    `uvm_component_utils(i2c_coverage)

    i2c_seq_item tr;

    // 명령, 주소, R/W 방향, 데이터 구간과 유효 조합의 기능 커버리지를 수집한다.
    covergroup i2c_cg;
        option.per_instance = 1;


        cp_cmd: coverpoint tr.cmd {
            bins start = {I2C_START};
            bins write = {I2C_WRITE};
            bins read = {I2C_READ};
            bins stop = {I2C_STOP};
        }


        cp_role: coverpoint tr.role {
            bins none = {ROLE_NONE};
            bins addr = {ROLE_ADDR};
            bins data = {ROLE_DATA};
        }


        cp_addr : coverpoint tr.master_tx_data[7:1]
                  iff (tr.cmd == I2C_WRITE && tr.role == ROLE_ADDR) {
            bins slave_addr = {7'h20};


        }


        cp_rw : coverpoint tr.master_tx_data[0]
                iff (tr.cmd == I2C_WRITE && tr.role == ROLE_ADDR) {
            bins wr = {1'b0}; bins rd = {1'b1};
        }


        cp_write_data : coverpoint tr.master_tx_data
                        iff (tr.cmd == I2C_WRITE && tr.role == ROLE_DATA) {
            bins data_zero = {8'h00};
            bins data_max = {8'hFF};
            bins data_low = {[8'h01 : 8'h3F]};
            bins data_mid = {[8'h40 : 8'hBF]};
            bins data_high = {[8'hC0 : 8'hFE]};
        }


        cp_read_data : coverpoint tr.slave_tx_data
                       iff (tr.cmd == I2C_READ && tr.role == ROLE_DATA) {
            bins data_zero = {8'h00};
            bins data_max = {8'hFF};
            bins data_low = {[8'h01 : 8'h3F]};
            bins data_mid = {[8'h40 : 8'hBF]};
            bins data_high = {[8'hC0 : 8'hFE]};
        }


        cp_master_rx_data : coverpoint tr.master_rx_data
                            iff (tr.cmd == I2C_READ && tr.role == ROLE_DATA) {
            bins rx_zero = {8'h00};
            bins rx_max = {8'hFF};
            bins rx_etc = {[8'h01 : 8'hFE]};
        }


        cp_slave_rx_data : coverpoint tr.slave_rx_data
                           iff (tr.cmd == I2C_WRITE && tr.role == ROLE_DATA) {
            bins rx_zero = {8'h00};
            bins rx_max = {8'hFF};
            bins rx_etc = {[8'h01 : 8'hFE]};
        }


        cx_cmd_role : cross cp_cmd, cp_role{
            ignore_bins start_addr = binsof(cp_cmd.start) && binsof(cp_role.addr);
            ignore_bins start_data = binsof(cp_cmd.start) && binsof(cp_role.data);

            ignore_bins write_none  = binsof(cp_cmd.write)  && binsof(cp_role.none);

            ignore_bins read_none  = binsof(cp_cmd.read)  && binsof(cp_role.none);
            ignore_bins read_addr  = binsof(cp_cmd.read)  && binsof(cp_role.addr);

            ignore_bins stop_addr  = binsof(cp_cmd.stop)  && binsof(cp_role.addr);
            ignore_bins stop_data  = binsof(cp_cmd.stop)  && binsof(cp_role.data);
        }


        cx_addr_rw : cross cp_addr, cp_rw;

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        i2c_cg = new();
    endfunction

    function void write(i2c_seq_item t);
        tr = t;
        i2c_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("COV", "====================================================",
                  UVM_LOW)
        `uvm_info("COV",
                  "============= Functional Coverage 결과 =============",
                  UVM_LOW)
        `uvm_info(
            "COV", $sformatf(
            "   전체              : %6.2f %%", i2c_cg.get_inst_coverage()),
            UVM_LOW)
        `uvm_info("COV", $sformatf(
                  "   command 종류      : %6.2f %%",
                  i2c_cg.cp_cmd.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  "   role 종류         : %6.2f %%",
                  i2c_cg.cp_role.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  "   slave address     : %6.2f %%",
                  i2c_cg.cp_addr.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info(
            "COV", $sformatf(
            "   R/W bit           : %6.2f %%", i2c_cg.cp_rw.get_inst_coverage()
            ), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  "   write data        : %6.2f %%",
                  i2c_cg.cp_write_data.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  "   read data         : %6.2f %%",
                  i2c_cg.cp_read_data.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  "   master rx data    : %6.2f %%",
                  i2c_cg.cp_master_rx_data.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  "   slave rx data     : %6.2f %%",
                  i2c_cg.cp_slave_rx_data.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  "   command X role    : %6.2f %%",
                  i2c_cg.cx_cmd_role.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  "   address X R/W     : %6.2f %%",
                  i2c_cg.cx_addr_rw.get_inst_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", "====================================================",
                  UVM_LOW)

        if (i2c_cg.get_inst_coverage() < 100.0) begin
            `uvm_warning(
                "COV",
                "커버리지 100% 미달! write/read/random 시나리오를 추가로 확인하세요.")
        end
    endfunction

endclass
