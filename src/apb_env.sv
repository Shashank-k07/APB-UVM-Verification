class apb_env extends uvm_env;
	`uvm_component_utils(apb_env)
	function new(string name="",uvm_component parent=null);
		super.new(name,parent);
	endfunction

	apb_sqr sqr;
	apb_driver dvr;
	apb_mon m;
	apb_sco s;
	apb_cov cov;

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		sqr = apb_sqr::type_id::create("sqr",this);
		dvr = apb_driver::type_id::create("dvr",this);
		m = apb_mon::type_id::create("m",this);
		s = apb_sco::type_id::create("s",this);
		cov = apb_cov::type_id::create("cov",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		dvr.seq_item_port.connect(sqr.seq_item_export);
		m.mon.connect(s.sco.analysis_export);
		m.mon.connect(cov.analysis_export);
	endfunction
endclass
