class Sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(Sequence)
    transaction tr;
	rand bit [1:0] random_bit;
    function new(string name = "Sequence");
        super.new(name);
		tr = transaction::type_id::create("tr");
    endfunction

    task body();
		test_start();
		test_end();
	endtask

	task test_start();	
		start_item(tr); 
		tr.mode = TEST_START; 
		tr.protocol = NORM;
		finish_item(tr);
	endtask
	task test_end();	
		start_item(tr); 
		tr.mode = TEST_END; 
		tr.protocol = NORM;
		finish_item(tr);
	endtask

	task reset(); 
		start_item(tr);
		tr.mode = RESET;
		tr.protocol = NORM;
		finish_item(tr);
	endtask
   
	task write(bit random); 
		start_item(tr); tr.mode = WRITE; tr.protocol = NORM;
		if(random) tr.randomize(); 
		finish_item(tr);
	endtask
   
	task read(bit random); 
		tr.mode = READ; tr.protocol = NORM;
		start_item(tr); 
		if(random) tr.randomize(); 
		finish_item(tr);
	endtask
endclass

class Sequence_reset extends Sequence #(transaction);
    `uvm_object_utils(Sequence_reset)
    function new(string name = "Sequence_reset");
        super.new(name);
		tr = transaction::type_id::create("tr");
    endfunction
    virtual task body();
		tr.protocol = NORM;
		test_start();
		repeat(loop)begin read(0); end
		test_end();
	endtask
endclass

class Sequence_axi extends Sequence #(transaction);
    `uvm_object_utils(Sequence_axi)
    function new(string name = "Sequence_axi");
        super.new(name);
		tr = transaction::type_id::create("tr");
    endfunction
    virtual task body();
		test_start(); 
		reset();
		repeat(loop)begin 
			axi_write	(0,5'd0,32'h00f0,4'b1111); 
			axi_read	(0,5'd0); 
			axi_write	(0,5'd8,32'h000c,4'b1111); 
			axi_read	(0,5'd8); 

			axi_write	(0,5'd12,32'haaaa,4'b1111); 
			axi_read	(0,5'd12); 
			axi_write	(0,5'd16,32'hbbbb,4'b1111); 
			axi_read	(0,5'd16); 
			axi_write	(0,5'd20,32'hcccc,4'b1111); 
			axi_read	(0,5'd20); 
			axi_write	(0,5'd24,32'hdddd,4'b1111); 
			axi_read	(0,5'd24); 
			axi_write	(0,5'd28,32'heeee,4'b1111); 
			axi_read	(0,5'd28); 
			repeat(10)begin axi_gpio	(1);	end
			axi_read	(0,5'd4); 
		end
		test_end();
	endtask
	
	task axi_write(bit random,logic [4:0] addr, logic [31:0] wdata, logic [3:0] wstrb); 
		start_item(tr); 
			tr.mode = WRITE; 
			tr.protocol = AXI;
			tr.random = random;
			tr.i_addr = addr;
			tr.i_wdata = wdata;
			tr.w_wstrb = wstrb;
		finish_item(tr);
	endtask
   
	task axi_read(bit random,logic [4:0] addr); 
		start_item(tr); 
			tr.mode = READ; 
			tr.protocol = AXI;
			tr.random = random;
			tr.i_addr = addr;
		finish_item(tr);
	endtask
	
	task axi_gpio(bit random); 
		start_item(tr); 
			tr.mode = IO; 
			tr.protocol = GPIO;
			tr.random = random;
		finish_item(tr);
	endtask
endclass

// 전체 시퀀스는 Reset, AXI 전송, GPIO 입출력 시나리오를 순서대로 실행한다.
class Sequence_all extends Sequence_axi #(transaction);
    `uvm_object_utils(Sequence_all)
    function new(string name = "Sequence_all");
        super.new(name);
		tr = transaction::type_id::create("tr");
    endfunction
    virtual task body();
		test_start(); 
		reset();
		repeat(loop)begin 
			std::randomize(random_bit);
			if(random_bit[1])begin axi_gpio	(1); end 
			else begin
				if(random_bit[0])	axi_write	(1,4'd4,32'haaaa,4'b1111); 
				else				axi_read	(1,4'd4); 
			end
		end	
		test_end();
	endtask
endclass
