class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)
    virtual spi_interface spi_if;
    uvm_analysis_port#(spi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_interface)::get(this, "", "spi_if", spi_if))
            `uvm_fatal(get_type_name(), "virtual interface를 config_db에서 찾지 못함")
    endfunction


    task run_phase(uvm_phase phase);
        spi_seq_item tr;
        logic [7:0] miso_capture;

        // SCLK 상승 에지에서 MISO를 복원하고 완료 시점의 양방향 수신 결과를 수집한다.
        forever begin
            @(posedge spi_if.clk iff spi_if.start == 1);

            tr           = spi_seq_item::type_id::create("tr");
            tr.slave_sel = spi_if.slave_sel;
            tr.cpol      = spi_if.cpol;
            tr.cpha      = spi_if.cpha;
            tr.clk_div   = spi_if.clk_div;
            tr.m_tx_data = spi_if.m_tx_data;
            tr.s0_tx_data = spi_if.s0_tx_data;
            tr.s1_tx_data = spi_if.s1_tx_data;


            @(posedge spi_if.sclk);


            miso_capture = 8'h00;
            repeat(7) begin
                @(posedge spi_if.sclk);
                miso_capture = {miso_capture[6:0], spi_if.miso};
            end


            if (tr.slave_sel == 1'b0)
                tr.m_rx_data = {tr.s0_tx_data[7], miso_capture[6:0]};
            else
                tr.m_rx_data = {tr.s1_tx_data[7], miso_capture[6:0]};

            @(posedge spi_if.clk iff spi_if.m_done == 1);
            tr.s0_rx_data = spi_if.s0_rx_data;
            tr.s1_rx_data = spi_if.s1_rx_data;

            `uvm_info(get_type_name(), $sformatf("%s", tr.convert2string()), UVM_HIGH)
            ap.write(tr);
        end
    endtask

endclass
