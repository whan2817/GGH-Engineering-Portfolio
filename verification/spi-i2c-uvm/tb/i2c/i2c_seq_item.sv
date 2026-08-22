typedef enum {
    I2C_START,
    I2C_WRITE,
    I2C_READ,
    I2C_STOP
} i2c_cmd_e;

typedef enum {
    ROLE_NONE,
    ROLE_ADDR,
    ROLE_DATA
} i2c_role_e;

class i2c_seq_item extends uvm_sequence_item;

    rand i2c_cmd_e cmd;
    rand i2c_role_e role;


    rand bit [7:0] master_tx_data;
    bit [7:0] master_rx_data;

    rand bit [7:0] slave_tx_data;
    bit [7:0] slave_rx_data;
    bit [7:0] exp_master_rx_data;
    bit [7:0] exp_slave_rx_data;

    `uvm_object_utils_begin(i2c_seq_item)
        `uvm_field_enum(i2c_cmd_e, cmd, UVM_DEFAULT)
        `uvm_field_enum(i2c_role_e, role, UVM_DEFAULT)
        `uvm_field_int(master_tx_data, UVM_DEFAULT)
        `uvm_field_int(master_rx_data, UVM_DEFAULT)
        `uvm_field_int(slave_tx_data, UVM_DEFAULT)
        `uvm_field_int(slave_rx_data, UVM_DEFAULT)
        `uvm_field_int(exp_master_rx_data, UVM_DEFAULT)
        `uvm_field_int(exp_slave_rx_data, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "i2c_seq_item");
        super.new(name);
    endfunction


endclass

