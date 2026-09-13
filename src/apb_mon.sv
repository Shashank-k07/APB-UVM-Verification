class apb_mon extends uvm_monitor;
	`uvm_component_utils(apb_mon);
	function new(string name="",uvm_component parent=null);
		super.new(name,parent);
	endfunction

	virtual apb_inf mvif;
	apb_trans tx;
	uvm_analysis_port#(apb_trans) mon;

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		tx = apb_trans::type_id::create("tx");
		mon = new("mon",this);
		uvm_config_db#(virtual apb_inf)::get(this,"","vif",mvif);
	endfunction

	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			@(posedge mvif.pclk);
			tx.paddr = mvif.paddr;
			tx.pprot = mvif.pprot;
			tx.psel = mvif.psel;
			tx.penable = mvif.penable;
			tx.pwrite = mvif.pwrite;
			tx.pwdata = mvif.pwdata;
			tx.pstrb = mvif.pstrb;
			@(posedge mvif.pclk);
			tx.pready = mvif.pready;
			tx.pslverr = mvif.pslverr;
			tx.prdata = mvif.prdata;
			mon.write(tx);
			@(posedge mvif.pclk);
		end
	endtask
endclass
