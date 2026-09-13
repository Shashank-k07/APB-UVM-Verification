class apb_seq extends uvm_sequence#(apb_trans);
	`uvm_object_utils(apb_seq)
	function new(string name="");
		super.new(name);
	endfunction

	task body();
		//1. Single write read transaction
		`uvm_do_with(req,{req.paddr==32'h0000;req.psel==1'b1;req.penable==1'b1;req.pwrite==1'b1;req.pstrb==4'hf;})
		`uvm_do_with(req,{req.paddr==32'h0000;req.psel==1'b1;req.penable==1'b1;req.pwrite==1'b0;})
	endtask
endclass
