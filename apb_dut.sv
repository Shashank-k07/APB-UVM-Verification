module apb_dut(
    input pclk,
    input presetn,
    input[31:0] paddr,
    input psel,
    input[2:0] pprot,
    input penable,
    input pwrite,
    input[31:0] pwdata,
    input[3:0] pstrb,
    output reg pready,
    output reg [31:0] prdata,
    output reg pslverr
);

    int j;

    reg[7:0] mem[1023:0];

    always@(posedge pclk)begin
        if(psel==1'b1)begin
            pready = 1'b1;
            if(penable==1'b1)begin
                if(paddr%4==0)begin
                    pslverr = 1'b0;
                    if(pwrite==1'b1)begin
                        	mem[paddr] = (pstrb[0]==1)? pwdata[7:0]: 8'h00;
			mem[paddr+1] =(pstrb[1]==1)? pwdata[15:8]: 8'h00;
					    mem[paddr+2] = (pstrb[2]==1)? pwdata[23:16]: 8'h00;
					    mem[paddr+3] = (pstrb[3]==1)? pwdata[31:24]: 8'h00;
                    end
                    if(pwrite==1'b0)begin
                        prdata[7:0]  = mem[paddr];
                        prdata[15:8] = mem[paddr+1];
                        prdata[23:16] = mem[paddr+2];
                        prdata[31:24] = mem[paddr+3];
                    end
                end
                else begin
                    $display("Address is unligned with data");
                    pslverr = 1'b1;
                end
            end
            else
                $display("PENABLE is 0 enable it to continue the operation");
        end
        else
            $display("Select the Slave in order for data transaction");
    end
endmodule
