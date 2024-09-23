`timescale 1ns/1ps
module sdram_controller_tb();
    logic 		          		iclk;
    logic 		          		ireset;
    logic                       iwrite_req;
    logic           [21:0]      iwrite_address;
    logic          [15:0]      iwrite_data;
    logic                      owrite_ack;
    logic                       iread_req;
    logic           [21:0]      iread_address;
    logic         [15:0]      oread_data;
    logic                      oread_ack;
    /////// SDRAM //////////
    logic		    [12:0]		DRAM_ADDR;
    logic		     [1:0]		DRAM_BA;
    logic		          		DRAM_CAS_N;
    logic		          		DRAM_CKE;
    logic		          		DRAM_CLK;
    logic		          		DRAM_CS_N;
	logic 			[15:0] 		dq_read;
	logic 			[15:0] 		dq_write;
    logic		          		DRAM_LDQM;
    logic		          		DRAM_RAS_N;
    logic		          		DRAM_UDQM;
    logic		          		DRAM_WE_N;

    logic [15:0] dq;
    // assign dq = DRAM_DQ;

    sdram_controller U2(.*);

	parameter CLK_FREQ = 200;
	parameter HALF_CLK_FREQ = 100;

	//Generate the clock signal (cycle is 100ns)
	initial iclk = 0; 
	always	#100 iclk = ~iclk;

    // Write first
    initial begin
        #20000;
        iwrite_req = 1;
        iread_req = 0;
        iwrite_address = 0; 
        iwrite_data = 19;
        #20000;
        iwrite_req = 0;
        #400;
        iread_req = 1;
        iread_address = 0;
        #20000;
        // iwrite_req = 1;
        #400;
        iread_req = 0;
    end

    // initial begin
    //     iwrite_req = 1;
    //     iwrite_address = 0;
    //     iwrite_data = 19;
    // end
    
    // //	CKE Loop generate
	// initial begin
	// 	#HALF_CLK_FREQ;
	// 	ienb = 1;
	// 	 for (int i = 0;i < 2 ;i++ ) begin
	// 	 	#100;
	// 	 	ienb = ~ienb;
	// 	end
	// end
	
	// //	CKE Loop generate
	// initial begin
	// 	#100;
	// 	ireq = 1;
	// end
	
	 initial begin 
	 	ireset = 1;
		#200;
	 	ireset = 0;
	 end


endmodule