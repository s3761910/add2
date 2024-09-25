// Top level module 
// In this module we will instantiate the Controller module developed earlier for a simple test
// The test will allow users to write data (from SW0 to SW7) 
// to address (from SW8 to SW9) of the SDRAM by pressing KEY0 on DE10 Standard Board. 
// Data from the memory can be read by pressing KEY1 and can be displayed on LEDR (from 0 to 7)


module sdram_controller_test(

	//////////// CLOCK //////////
	input logic 		          		CLOCK_50,

	//////////// SDRAM //////////
	output logic		    [12:0]		DRAM_ADDR,
	output logic		    [1:0]		DRAM_BA,
	output logic		          		DRAM_CAS_N,
	output logic		          		DRAM_CKE,
	output logic		          		DRAM_CLK,
	output logic		          		DRAM_CS_N,
	// output logic           [15:0]		DRAM_DQ,
	output logic		          		DRAM_LDQM,
	output logic		          		DRAM_RAS_N,
	output logic		          		DRAM_UDQM,
	output logic		          		DRAM_WE_N,
	output	logic		[31:0] 			GPIO,

	output logic	idle_flag,
	output logic	nop1_flag,
	output logic	pre_flag,
	output logic	ref_flag,
	output logic	nop2_flag,
	output logic	load_flag,
	output logic	nop3_flag,
	output logic	fin_flag,
	output logic 	gpio_ref_cycles,
	output logic 	gpio_init_begin_counter,
	//////////// KEY //////////
	input logic 		     [2:0]		KEY,

	//////////// LED //////////
	output logic		     [9:0]		LEDR,
 
	//////////// SW //////////
	input logic 		     [9:0]		SW
);



//=======================================================
//  REG/WIRE declarations
//=======================================================
	logic   	[127:0]		data;
	logic     	[2:0]   		state;
	logic     	[2:0]   		next_state;

	logic   	[21:0]  		address         ;
	logic            		reset;

	logic            		write_command;
	logic            		read_command;
	logic            		write_finished;
	logic            		read_finished;
	logic  	[127:0] 		write_data;
	logic  	[127:0]		 read_data;

	logic             		write_request;
	logic            		read_request;
	

// STATES - State
	parameter INIT      = 3'b000;
	parameter WRIT_START = 3'b001;
	parameter WRIT_FIN  = 3'b010; 	
	parameter READ_START = 3'b011;
	parameter READ_FIN  = 3'b100;

//=======================================================
//  Structural coding
//=======================================================
	assign  write_data      = {112'b0, SW[7:0]};
	assign  address      	= {22'b0, SW[9:8]};

	assign  LEDR            = data[9:0];
	assign GPIO[0] = CLOCK_50;
	assign GPIO[1] = state[0];
	assign GPIO[2] = state[1];
	assign GPIO[3] = state[2];
	assign GPIO[4] = write_finished;
	assign GPIO[5] = read_finished;
	assign GPIO[6] = write_request;
	assign GPIO[7] = read_request;
	assign GPIO[8] = reset;
	assign GPIO[9] = DRAM_CLK;
	assign GPIO[10] = idle_flag;
	assign GPIO[11] = nop1_flag;
	assign GPIO[12] = pre_flag;
	assign GPIO[13] = ref_flag;
	assign GPIO[14] = nop2_flag;
	assign GPIO[15] = load_flag;
	assign GPIO[16] = nop3_flag;
	assign GPIO[17] = fin_flag;
	assign GPIO[18] = gpio_ref_cycles;
	assign GPIO[19] = gpio_init_begin_counter;
	assign GPIO[20] = CLOCK_50;
	assign GPIO[21] = KEY[0];
	assign GPIO[22] = KEY[1];
	// assign GPIO[23] = CLOCK_50;
	// assign GPIO[24] = CLOCK_50;
	// assign GPIO[25] = CLOCK_50;
	// assign GPIO[26] = CLOCK_50;
	// assign GPIO[27] = CLOCK_50;
	// assign GPIO[28] = CLOCK_50;
	// assign GPIO[29] = CLOCK_50;
	// assign GPIO[30] = CLOCK_50;
	// assign GPIO[31] = CLOCK_50;


	assign  write_command   = ~KEY[0];
	assign  read_command    = ~KEY[1];
	assign  reset 			= ~KEY[2];
	//State transition
	always_ff @(posedge CLOCK_50)
	begin
		state <=  next_state;
	end

	//Next state computation FSM
	always_comb	begin
		case(state)
			INIT:
				if(write_command)
					next_state  = WRIT_START;
				else if(read_command)
					next_state  = READ_START;
				else
					next_state  = INIT;
					
			WRIT_START:
				if(write_finished)
					next_state  = WRIT_FIN;
				else
					next_state  = WRIT_START;
			WRIT_FIN:
				next_state      = INIT;
				
			READ_START:
				if(read_finished)
					next_state  = READ_FIN;
				else
					next_state  = READ_START;
			READ_FIN:
				next_state      = INIT;
			default: begin
				next_state  = INIT;
			end
		endcase
	end
	
	//Output logic computation for the FSM
	always_comb begin
		case(state)
			INIT:
			begin
				write_request   =  1'b0;
				read_request    =  1'b0;
				data            =  0;
			end
			
			WRIT_START:
			begin
				write_request   =  1'b1;
				read_request    =  1'b0;
				data            =  0;
			end
			WRIT_FIN:
			begin
				write_request   =  1'b0;
				read_request    =  1'b0;
				data            =  0;
			end
			
			READ_START:
			begin
				write_request   =  1'b0;
				read_request    =  1'b1;
				data            =  0;
			end
			READ_FIN:
			begin
				write_request   =  1'b0;
				read_request    =  1'b0;
				data            =  read_data;
			end
			default: begin
				write_request   =  1'b1;
				read_request    =  1'b1;
				data = 324;
			end
		endcase
	end
	
	//Instantiate the SDRAM Controller Module
	sdram_controller  u0(
		.iclk(CLOCK_50),
		.ireset(reset),
		
		.iwrite_req(write_request),
		.iwrite_address(address),
		.iwrite_data(write_data),
		.owrite_ack(write_finished),
		
		.iread_req(read_request),
		.iread_address(address),
		.oread_data(read_data),
		.oread_ack(read_finished),
		
		//////////// SDRAM //////////
		.DRAM_ADDR(DRAM_ADDR),
		.DRAM_BA(DRAM_BA),
		.DRAM_CAS_N(DRAM_CAS_N),
		.DRAM_CKE(DRAM_CKE),
		.DRAM_CLK(DRAM_CLK),
		.DRAM_CS_N(DRAM_CS_N),
		//.DRAM_DQ(DRAM_DQ),
		.DRAM_LDQM(DRAM_LDQM),
		.DRAM_RAS_N(DRAM_RAS_N),
		.DRAM_UDQM(DRAM_UDQM),
		.DRAM_WE_N(DRAM_WE_N)
	);

endmodule
