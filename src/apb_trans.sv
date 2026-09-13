class apb_trans extends uvm_sequence_item;
	`uvm_object_utils(apb_trans)
	function new(string name="");
		super.new(name);
	endfunction

	rand bit[31:0] paddr;
	rand bit[2:0]  pprot;
	rand bit psel;
	rand bit penable;
	rand bit pwrite;
	rand bit[31:0] pwdata;
	rand bit[3:0] pstrb;
	     bit pready;
	     bit pslverr;
	     bit[31:0] prdata;
endclass
