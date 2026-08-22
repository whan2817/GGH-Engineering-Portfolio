class spi_driver extends uvm_driver#(spi_seq_item);
    `uvm_component_utils(spi_driver)
    virtual spi_interface spi_if;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_interface)::get(this, "", "spi_if", spi_if))
            `uvm_fatal(get_type_name(), "virtual interface를 config_db에서 찾지 못함")
    endfunction

    task run_phase(uvm_phase phase);

        spi_if.drv_cb.start      <= 0;
        spi_if.drv_cb.cpol       <= 0;
        spi_if.drv_cb.cpha       <= 0;
        spi_if.drv_cb.clk_div    <= 8'd9;
        spi_if.drv_cb.slave_sel  <= 0;
        spi_if.drv_cb.m_tx_data  <= 0;
        spi_if.drv_cb.s0_tx_data  <= 0;
        spi_if.drv_cb.s1_tx_data  <= 0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_transaction(req);
            seq_item_port.item_done();
        end
    endtask

    // DUT 유휴 상태에서 설정값을 전달하고 start부터 완료까지 한 항목을 구동한다.
    task drive_transaction(spi_seq_item req);

        @(spi_if.drv_cb);
        wait(spi_if.drv_cb.m_busy == 0);

        spi_if.drv_cb.cpol      <= req.cpol;
        spi_if.drv_cb.cpha      <= req.cpha;
        spi_if.drv_cb.m_tx_data <= req.m_tx_data;
        spi_if.drv_cb.clk_div   <= 8'd9;
        spi_if.drv_cb.slave_sel <= req.slave_sel;
        spi_if.drv_cb.s0_tx_data <= req.s0_tx_data;
        spi_if.drv_cb.s1_tx_data <= req.s1_tx_data;
        @(spi_if.drv_cb);


        spi_if.drv_cb.start <= 1;
        @(spi_if.drv_cb);
        spi_if.drv_cb.start <= 0;

        @(posedge spi_if.clk iff spi_if.m_done == 1);

        `uvm_info(get_type_name(), $sformatf("구동완료: %s", req.convert2string()), UVM_HIGH)
    endtask
endclass
