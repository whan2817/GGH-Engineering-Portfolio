class Dut_test extends uvm_test;
    `uvm_component_utils(Dut_test)
	Sequence #(transaction) seq;
    Environment env;
    function new(string name = "Dut_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = Environment::type_id::create("env", this);
		uvm_config_db#(bit)::set(this, "env.cov", "cov_enable", 1'b0);
		case (mode_sel)
			"RESET" : begin `uvm_info("TEST",$sformatf("RESET"), UVM_LOW)
				seq = Sequence_reset::type_id::create("seq");
			end
			"NORMAL" : begin `uvm_info("TEST",$sformatf("WRITE"), UVM_LOW)
				seq = Sequence_axi::type_id::create("seq");
			end
			"ALL" : begin `uvm_info("SEQ",$sformatf("ALL"), UVM_LOW)
				seq = Sequence_all::type_id::create("seq");
			end
		endcase
		
    endfunction
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("TEST", "Dut_test raise_objection", UVM_HIGH)
        seq.start(env.agent.sqr);
        phase.drop_objection(this);
        `uvm_info("TEST", "Dut_test drop_objection", UVM_HIGH)
    endtask

	function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

	function void report_phase(uvm_phase phase);
		super.report_phase(phase);
	endfunction
endclass


