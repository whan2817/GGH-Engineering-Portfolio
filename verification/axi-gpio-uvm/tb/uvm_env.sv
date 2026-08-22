class Environment extends uvm_env;
    `uvm_component_utils(Environment)
    
	Agent		agent;
    Scoreboard 	scb;
    Coverage	cg;

    function new(string name = "Environment", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent = Agent::type_id::create("agent", this);
        scb   = Scoreboard::type_id::create("scb", this);
        cg    = Coverage::type_id::create("cg", this);

    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        agent.mon.send.connect(scb.recv);
        agent.mon.send.connect( cg.cov_fifo.analysis_export);
    endfunction

endclass
