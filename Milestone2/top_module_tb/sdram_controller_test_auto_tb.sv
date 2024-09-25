`timescale 1ns/1ps
module sdram_controller_auto_tb();
	logic 		          		iclk;
	logic 		          		ireset;
	logic                       iwrite_req;
	logic           [21:0]      iwrite_address;
	logic          [15:0]      iwrite_data;
	logic                      owrite_ack;
	logic                       iread_req;
	logic           [21:0]      iread_address;
	logic           [15:0]      oread_data;
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

	logic                       iwrite_req_array [0:255];
	logic           [21:0]      iwrite_address_array [0:255];
	logic           [15:0]      iwrite_data_array [0:255];
	logic                       iread_req_array [0:255];
	logic           [21:0]      iread_address_array [0:255];
	logic           [255:0]     time_ [0:255];

	// logic [15:0] dq;
	// assign dq = DRAM_DQ;

	sdram_controller U2(.*);

	parameter CLK_FREQ = 200;
	parameter HALF_CLK_FREQ = 100;

	//Generate the clock signal (cycle is 100ns)
	initial iclk = 0;
	always	#100 iclk = ~iclk;

	// Write first
	initial begin
		$readmemb("iwrite_req.txt", iwrite_req_array);
		$readmemb("iwrite_address.txt", iwrite_address_array);
		$readmemb("iwrite_data.txt", iwrite_data_array);
		$readmemb("iread_req.txt", iread_req_array);
		$readmemb("iread_address.txt", iread_address_array);
		$readmemh("time_.txt", time_);
		for (int i = 0; i < 5; i++) begin
			$display("%i", iwrite_data_array[i]);
			$display("%i", iread_address_array[i]);
			$display("%i", iwrite_address_array[i]);
			#time_[i];
			iwrite_req = iwrite_req_array[i];
			iread_req = iread_req_array[i];
			iwrite_data = 		iwrite_data_array[i];
			iread_address = 	iread_address_array[i];
			iwrite_address = iwrite_address_array[i];
		end
	end

	// AUTO log 
	// initial begin
	// 	$monitor("")
// owrite_ack, oread_data, oread_ack, DRAM_ADDR, DRAM_BA, DRAM_CAS_N, DRAM_CKE, DRAM_CLK, DRAM_CS_N, DRAM_LDQM, DRAM_RAS_N, DRAM_UDQM, DRAM_WE_N
	// end
	
	initial begin 
	 	ireset = 1;
		#200;
	 	ireset = 0;
	 end

endmodule
