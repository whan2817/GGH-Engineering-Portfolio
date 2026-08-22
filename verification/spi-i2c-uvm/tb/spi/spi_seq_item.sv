class spi_seq_item extends uvm_sequence_item;
    rand logic       slave_sel;
    rand logic       cpol;
    rand logic       cpha;
    rand logic [7:0] clk_div;
    rand logic [7:0] m_tx_data;
    rand logic [7:0] s0_tx_data;
    rand logic [7:0] s1_tx_data;

    logic [7:0] m_rx_data;
    logic [7:0] s0_rx_data;
    logic [7:0] s1_rx_data;

    constraint c_clk_div { clk_div == 8'd9; }
    constraint c_cpol_cpha {
        cpol == 1'b0;
        cpha == 1'b0;
    }

    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(slave_sel,  UVM_ALL_ON)
        `uvm_field_int(cpol,       UVM_ALL_ON)
        `uvm_field_int(cpha,       UVM_ALL_ON)
        `uvm_field_int(clk_div,    UVM_ALL_ON)
        `uvm_field_int(m_tx_data,  UVM_ALL_ON)
        `uvm_field_int(s0_tx_data,  UVM_ALL_ON)
        `uvm_field_int(s1_tx_data,  UVM_ALL_ON)
        `uvm_field_int(m_rx_data,  UVM_ALL_ON)
        `uvm_field_int(s0_rx_data, UVM_ALL_ON)
        `uvm_field_int(s1_rx_data, UVM_ALL_ON)
    `uvm_object_utils_end

    function string convert2string();
        return $sformatf(
            "slave%0d | m_tx=0x%02h s0_tx=0x%02h s1_tx=0x%02h | m_rx=0x%02h s0_rx=0x%02h s1_rx=0x%02h",
            slave_sel,
            m_tx_data, s0_tx_data, s1_tx_data,
            m_rx_data, s0_rx_data, s1_rx_data
        );
    endfunction
endclass

