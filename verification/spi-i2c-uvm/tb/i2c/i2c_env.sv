class i2c_env extends uvm_env;
    `uvm_component_utils(i2c_env)
    i2c_agent agt;
    i2c_scoreboard scb;
    i2c_coverage cov;

    function new(string name = "i2c_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = i2c_agent::type_id::create("agt", this);
        scb = i2c_scoreboard::type_id::create("scb", this);
        cov = i2c_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ip.connect(scb.imp);
        agt.mon.ip.connect(cov.analysis_export);
    endfunction
endclass
