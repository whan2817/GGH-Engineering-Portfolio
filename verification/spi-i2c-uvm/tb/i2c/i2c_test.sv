class i2c_base_test extends uvm_test;
    `uvm_component_utils(i2c_base_test)
    i2c_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = i2c_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction
endclass


class i2c_write_test extends i2c_base_test;
    `uvm_component_utils(i2c_write_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_write_seq seq;
        phase.raise_objection(this);
        seq = i2c_write_seq::type_id::create("seq");
        repeat(20) begin
            if (!seq.randomize()) `uvm_error("TEST", "seq randomize FAIL")
            seq.start(env.agt.sqr);
        end
        #100;
        phase.drop_objection(this);
    endtask
endclass


class i2c_read_test extends i2c_base_test;
    `uvm_component_utils(i2c_read_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_read_seq seq;
        phase.raise_objection(this);
        seq = i2c_read_seq::type_id::create("seq");
        repeat(20) begin
            if (!seq.randomize()) `uvm_error("TEST", "seq randomize FAIL")
            seq.start(env.agt.sqr);
        end
        #100;
        phase.drop_objection(this);
    endtask
endclass


class i2c_multi_write_test extends i2c_base_test;
    `uvm_component_utils(i2c_multi_write_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_multi_write_seq seq;
        phase.raise_objection(this);
        seq = i2c_multi_write_seq::type_id::create("seq");
        if (!seq.randomize()) `uvm_error("TEST", "seq randomize FAIL")
        seq.start(env.agt.sqr);
        #100;
        phase.drop_objection(this);
    endtask
endclass


class i2c_random_test extends i2c_base_test;
    `uvm_component_utils(i2c_random_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_random_seq seq;
        phase.raise_objection(this);
        seq = i2c_random_seq::type_id::create("seq");
        if (!seq.randomize()) `uvm_error("TEST", "seq randomize FAIL")

        seq.start(env.agt.sqr);
        #100;
        phase.drop_objection(this);
    endtask
endclass


class i2c_full_test extends i2c_base_test;
    `uvm_component_utils(i2c_full_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        i2c_write_seq write_seq;
        i2c_read_seq  read_seq;
        i2c_multi_write_seq multi_write_seq;
        i2c_random_seq random_seq;
        i2c_boundary_data_seq boundary_seq;

        phase.raise_objection(this);

        write_seq = i2c_write_seq::type_id::create("write_seq");
        read_seq  = i2c_read_seq::type_id::create("read_seq");
        multi_write_seq = i2c_multi_write_seq::type_id::create("multi_write_seq");
        random_seq = i2c_random_seq::type_id::create("random_seq");
        boundary_seq = i2c_boundary_data_seq::type_id::create("boundary_seq");

        if(!write_seq.randomize()) `uvm_error("TEST", "randomize FAIL")
        write_seq.start(env.agt.sqr);
        if(!read_seq.randomize()) `uvm_error("TEST", "randomize FAIL")
        read_seq.start(env.agt.sqr);
        if(!multi_write_seq.randomize()) `uvm_error("TEST", "randomize FAIL")
        multi_write_seq.start(env.agt.sqr);
        if(!random_seq.randomize()) `uvm_error("TEST", "randomize FAIL")


        random_seq.start(env.agt.sqr);
        boundary_seq.start(env.agt.sqr);

        #100;
        phase.drop_objection(this);
    endtask
endclass
