`include "uvm_macros.svh"
import uvm_pkg::*;
import i2c_pkg::*;


module tb_top ();
    logic clk;
    logic rst;

initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0, tb_top);
end

    initial begin
        clk = 0;
        rst = 1;
        #20;
        rst = 0;
    end
    always #5 clk = ~clk;

    i2c_if i2c_if(clk);

    i2c_loopback dut (
        .clk            (i2c_if.clk),
        .rst            (i2c_if.rst),
        .cmd_start      (i2c_if.cmd_start),
        .cmd_write      (i2c_if.cmd_write),
        .cmd_read       (i2c_if.cmd_read),
        .cmd_stop       (i2c_if.cmd_stop),
        .master_tx_data (i2c_if.master_tx_data),
        .slave_tx_data  (i2c_if.slave_tx_data),
        .master_rx_data (i2c_if.master_rx_data),
        .slave_rx_data  (i2c_if.slave_rx_data),
        .busy           (i2c_if.busy),
        .master_done    (i2c_if.master_done),
        .slave_done     (i2c_if.slave_done)
    );

    initial begin
        uvm_config_db#(virtual i2c_if)::set(null, "*", "i2c_if", i2c_if);
        run_test("i2c_test");
    end

endmodule
