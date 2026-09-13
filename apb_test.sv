class apb_test extends uvm_test;
	`uvm_component_utils(apb_test);
	function new(string name="",uvm_component parent=null);
		super.new(name,parent);
	endfunction

	apb_env env;

	function void build_phase(uvm_phase phase);
		 super.build_phase(phase);
	 	env = apb_env::type_id::create("env",this);
	endfunction		

	task run_phase(uvm_phase phase);
		apb_seq seq;
		seq = apb_seq::type_id::create("seq");
		phase.raise_objection(this);
		seq.start(env.sqr);
		#100;
		phase.drop_objection(this);
	endtask
endclass
