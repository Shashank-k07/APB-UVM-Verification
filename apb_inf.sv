interface apb_inf(input bit pclk, input bit presetn);
	logic[31:0] paddr;
    	logic[2:0] pprot;
   	logic psel;
    	logic penable;
    	logic pwrite;;
    	logic[31:0] pwdata;
    	logic[3:0] pstrb;
    	logic pready;
    	logic[31:0] prdata;
    	logic pslverr;
endinterface
