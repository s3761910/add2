`timescale 1ns/1ps
module sdram_initialize_tb();
	
	logic iclk;
	logic ireset;
	logic ireq;	//Request signal to initialize the memory
	logic ienb;	//Enable signal to start the initialization
	logic ofin;	//Acknowledgment signal to indicate to other modules, 
													//when initialization is done
	logic DRAM_CLK;
	logic DRAM_CKE;
	logic [12:0]DRAM_ADDR;		
	logic [1:0]DRAM_BA;		//bank select
	logic DRAM_CAS_N;	//column access
	logic DRAM_CS_N;	//chip select
	logic DRAM_RAS_N;	//row access strobe
	logic DRAM_WE_N;	//write enable strobe
	logic DRAM_LDQM; //CONTROL input buffer (write mode; low = active;) >< control output buffer (read mode; low = inactive)
	logic DRAM_UDQM;	//
	logic [15:0]DRAM_DQ;

	sdram_initialize U2(.*, .ireq(ireq));
	
	parameter CLK_FREQ = 200;
	parameter HALF_CLK_FREQ = 100;

	//Generate the clock signal (cycle is 100ns)
	initial iclk = 0; 
	always	#100 iclk = ~iclk;

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

		// #50;
		// for (int i = 0;i < 40 ;i++ ) begin
		// 	#100;
		// 	ireq = ~ireq;
		// end
	end
	
	// // reset
	 initial begin 
	// 	ireset = 1;
	// 	#20;
	 	ireset = 1;
		// #600;
		#100;
	 	ireset = 0;
	 end

	// initial ireq = 0; 
	// always	#100 ireq = ~ireq;


endmodule	