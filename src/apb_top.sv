module apb_top;
	bit pclk;
    bit presetn;


    apb_inf vif(pclk, presetn);

    initial begin
        pclk = 0;
        forever #5 pclk = ~pclk;
    end

    initial begin
        presetn = 1'b0;
        #10;
        presetn = 1'b1;
    end

    

    apb_env env;

    apb_dut dut(.pclk(vif.pclk),
                .presetn(vif.presetn),
                .psel(vif.psel),
                .paddr(vif.paddr),
                .pprot(vif.pprot),
                .penable(vif.penable),
                .pwrite(vif.pwrite),
                .pwdata(vif.pwdata),
                .pstrb(vif.pstrb),
                .prdata(vif.prdata),
                .pslverr(vif.pslverr),
                .pready(vif.pready));
	initial begin
		uvm_config_db#(virtual apb_inf)::set(null,"*","vif",vif);
	end

	initial begin
		run_test("apb_test");
	end
	endmodule
