class apb_driver extends uvm_driver#(apb_trans);
	`uvm_component_utils(apb_driver)
	function new(string name="",uvm_component parent=null);
		super.new(name,parent);
	endfunction

	virtual apb_inf dvif;

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		uvm_config_db#(virtual apb_inf)::get(this,"*","vif",dvif);
	endfunction

	task  run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			seq_item_port.get_next_item(req);
			@(posedge dvif.pclk);
			dvif.paddr = req.paddr;
			dvif.pprot = req.pprot;
			dvif.psel = req.psel;
			dvif.penable = req.penable;
			dvif.pwrite = req.pwrite;
			dvif.pwdata = req.pwdata;
			dvif.pstrb = req.pstrb;
			@(posedge dvif.pclk);
			req.pready = dvif.pready;
			req.prdata = dvif.prdata;
			req.pslverr = dvif.pslverr;
			seq_item_port.item_done();
		end
	endtask
endclass
