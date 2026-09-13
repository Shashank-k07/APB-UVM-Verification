class apb_sco extends uvm_scoreboard;
	`uvm_component_utils(apb_sco);
	function new(string name="",uvm_component parent=null);
		super.new(name,parent);
	endfunction

	bit exp_pready;
	bit exp_pslverr;
	bit[31:0] exp_prdata;
	apb_trans tx;
	uvm_tlm_analysis_fifo#(apb_trans) sco;

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		tx = apb_trans::type_id::create("tx");
		sco = new("sco",this);
	endfunction

	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever begin
			sco.get(tx);
			exp_pready = (tx.psel==1'b1)?1'b1:1'b0;
			exp_pslverr = (tx.paddr%4==0)?1'b0:1'b1;
			if(tx.pstrb[0])
				exp_prdata = tx.pwdata[7:0];
			if(tx.pstrb[1])
				exp_prdata = tx.pwdata[15:8];
			if(tx.pstrb[2])
				exp_prdata = tx.pwdata[23:16];
			if(tx.pstrb[3])
				exp_prdata = tx.pwdata[31:24];

			
			if(exp_pready==tx.pready&&exp_pslverr==tx.pslverr&&exp_prdata==tx.prdata)
				$display("SCOREBOARD PASS::\n------------------------------\nExpected data are\n------------------\nprdata = %h\npready = %0d\npslverr = %0d\nActual data are\n-------------------------\nprdata = %h\npready = %0d\npslverr = %0d",exp_prdata, exp_pready, exp_pslverr, tx.prdata, tx.pready, tx.pslverr);
			if(exp_pready!=tx.pready&&exp_pslverr!=tx.pslverr&&exp_prdata!=tx.prdata)
				$display("SCOREBOARD FAIL::\n------------------------------\nExpected data are\n------------------\nprdata = %h\npready = %0d\npslverr = %0d\nActual data are\n-------------------------\nprdata = %h\npready = %0d\npslverr = %0d",exp_prdata, exp_pready, exp_pslverr, tx.prdata, tx.pready, tx.pslverr);
		end
	endtask
endclass
