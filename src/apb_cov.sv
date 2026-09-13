class apb_cov extends uvm_subscriber#(apb_trans);
	`uvm_component_utils(apb_cov)
	apb_trans tx;
	covergroup cg;
		A:coverpoint tx.paddr;
		B:coverpoint tx.pprot;
		C:coverpoint tx.psel;
		D:coverpoint tx.penable;
		E:coverpoint tx.pwrite;
		F:coverpoint tx.pwdata;
		G:coverpoint tx.pstrb;
		H:coverpoint tx.prdata;
		I:coverpoint tx.pready;
		J:coverpoint tx.pslverr;
	endgroup

	function new(string name="",uvm_component parent=null);
		super.new(name,parent);
		cg = new();
	endfunction

	function void write(apb_trans t);
		tx = t;
		cg.sample();
	endfunction
endclass
