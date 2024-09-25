`timescale 1ns/1ps
module sdram_write_tb();
	logic                      iclk;
	logic                      ireset;
	logic                      ireq;	//Request signal to initialize the memory
	logic                      ienb;	//Enable signal to start the initialization
	logic                      ofin;	//Acknowledgment signal to indicate to other modules; 
						//when initialization is done
	logic          [12:0]     	irow;
	logic           [9:0]      	icolumn;
	logic           [1:0]      	ibank;
	logic		   [15:0]		idata;
	logic		          		DRAM_CLK;
	logic		          		DRAM_CKE;
	logic  	    	[12:0]		DRAM_ADDR;
	logic		     [1:0]		DRAM_BA;
	logic		          		DRAM_CAS_N;
	logic		          		DRAM_CS_N;
	logic		          		DRAM_RAS_N;
	logic		          		DRAM_WE_N;
	logic		          		DRAM_LDQM;
	logic		          		DRAM_UDQM;
	logic 		    [15:0]		DRAM_DQ;

    sdram_write U2(.*);

	parameter CLK_FREQ = 200;
	parameter HALF_CLK_FREQ = 100;

	//Generate the clock signal (cycle is 100ns)
	initial iclk = 0; 
	always	#100 iclk = ~iclk;

	initial begin
		// irow = 1;
		// icolumn = 1;
		// ibank = 1;
		// irow = 0;
		// icolumn = 0;
		// ibank = 0;
		// DRAM_DQ = 29;

		// iclk = 1;
		// ireset = 1;
		// ireq = 1;	//Request signal to initialize the memory
		// ienb = 1;	//Enable signal to start the initialization
		irow = 0;
		icolumn = 0;
		ibank = 0;
		idata = 29;
	end
    
    //	CKE Loop generate
	initial begin
		#HALF_CLK_FREQ;
		ienb = 1;
		 for (int i = 0;i < 2 ;i++ ) begin
		 	#100;
		 	ienb = ~ienb;
		end
	end
	
	//	CKE Loop generate
	initial begin
		#100;
		ireq = 1;
	end
	
	 initial begin 
	 	ireset = 1;
		#100;
	 	ireset = 0;
	 end

endmodule
