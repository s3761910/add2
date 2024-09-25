//	Modified from the work from https://github.com/Arkowski24/sdram-controller
// 	Simple SDRAM Initialize Module 
// 	The module is built using FSM to perform Initialization process for SDRAM
// For this controller, the following settings are used:
//  	Write Bust      -- Single Location  M9=1;
//  	CAS Latency     -- 2 M[4-6]=010;
// 	Burst           -- Sequential M3=0;
//  	Burst Length    -- 8 M[0-2]= 011;

module sdram_initialize(	
	input logic                       iclk,
	input logic                       ireset,
	input logic                       ireq,	//Request signal to initialize the memory
	input logic                 	  ienb,
	//Enable signal to start the initialization
	output logic                      ofin,	//Acknowledgment signal to indicate to other modules, 
												//when initialization is done

	output logic		          		DRAM_CLK,
	output logic		          		DRAM_CKE,
	output logic		    [12:0]		DRAM_ADDR,		
	output logic		     [1:0]		DRAM_BA,	//bank select
	output logic		          		DRAM_CAS_N,	//column access
	output logic		          		DRAM_CS_N,	//chip select
	output logic		          		DRAM_RAS_N,	//row access strobe 
	output logic		          		DRAM_WE_N,	//write enable strobe
	output logic		          		DRAM_LDQM, //CONTROL input buffer (write mode, low = active,) >< control output logic buffer (read mode, low = inactive)
	output logic		          		DRAM_UDQM,	//
	output logic 		    [15:0]		DRAM_DQ,//store input data during write command (latched), print output data when read command (buffered)

	output logic	idle_flag,
	output logic	nop1_flag,
	output logic	pre_flag,
	output logic	ref_flag,
	output logic	nop2_flag,
	output logic	load_flag,
	output logic	nop3_flag,
	output logic	fin_flag,
	output logic 	gpio_ref_cycles,
	output logic 	gpio_init_begin_counter
//	
// //	//////////// KEY //////////
// input 		     [1:0]		KEY,
// //
// //	//////////// LED //////////
// output		     [9:0]		LEDR,
// // 
// //	//////////// SW //////////
// input 		     [9:0]		SW,
);
//=======================================================
//  GPIOs declarations
//=======================================================
//=======================================================
//  REG/WIRE declarations
//=======================================================
	logic      [2:0]  next_state;
	logic      [2:0]  state       = 3'b000;	//State register
	logic      [3:0]  command     = 4'h0;		//Command register to be sent to SDRAM
	logic     [12:0]  address     = 13'h0;	//Address register
	logic      [1:0]  bank        = 2'b00;	//Bank register
	logic      [1:0]  dqm         = 2'b11;	//Masking registers for write mode making the input data buffer 
	logic             ready       = 1'b0;
	logic     [15:0]  counter     = 16'h0;
	logic             ctr_reset   = 0;
	logic	ref_cycles;
	logic	init_begin_counter;
 
// STATES - State
	parameter IDLE      = 3'b000;
	parameter INIT_NOP1 = 3'b001;	//
	parameter INIT_PRE  = 3'b010;	//PRECHARGE	
	parameter INIT_REF  = 3'b011;	//REFRESH
	parameter INIT_NOP2 = 3'b100;
	parameter INIT_LOAD = 3'b101;	//load MODE
	parameter INIT_NOP3 = 3'b110;
	parameter INIT_FIN  = 3'b111;	//ACT
//Commands send to SDRAM
	parameter CMD_NOP = 4'b0111;
	parameter CMD_MRS = 4'b0000;		//Mode or MRS
	parameter CMD_REF = 4'b0001;		//Auto Refresh
	parameter CMD_PALL = 4'b0010;		//Precharge ALL BANK

	assign ofin                                             = ready;

	assign DRAM_ADDR                                        = ienb ? address    : 13'bz;
	assign DRAM_BA                                          = ienb ? bank       : 2'bz;
	assign {DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N}   = ienb ? command    : 4'bz;
	assign {DRAM_UDQM, DRAM_LDQM}                           = ienb ? dqm        : 2'bz;
	assign DRAM_CLK                                         = ienb ? ~iclk      : 1'bz;
	assign DRAM_CKE                                         = ienb ? 1'b1       : 1'bz;
	assign DRAM_DQ                                          = ienb ? 16'h0000   : 16'bz;

	always_ff @(posedge iclk ,posedge ctr_reset)
	begin
		 if(ctr_reset)
			  counter <=  16'h0;
		 else
			  counter <=  (counter + 1'b1);
	end

	//ref_cycles > 16 - refresh, nop - 8 times
	assign ref_cycles = (counter >= 16);
	assign init_begin_counter = (counter >= 10000);

	//State Transition 
	always_ff @(posedge iclk)
	begin
		if(ireset)
			state <=  IDLE;
		else
			state <=  next_state;
	end

	//Next state computation 
	// or ireq
	always_comb	begin
		case(state)
			//IDLE
			IDLE:																	
				if(ireq)
					next_state  = INIT_NOP1;
				else
					next_state  = IDLE;
			//NOP - POWER UP
			INIT_NOP1:																	//NOP
				if(init_begin_counter)												//Start to count
					next_state  = INIT_PRE;
				else
					next_state  = INIT_NOP1;
			INIT_PRE:																	//Precharge All banks
				next_state      = INIT_REF;
			INIT_REF:																	//Auto Refresh
				next_state      = INIT_NOP2;
			INIT_NOP2:																	//Nop
				if(ref_cycles)															//Check if enough refresh cycles
					next_state  = INIT_LOAD;
				else
					next_state  = INIT_REF;
			INIT_LOAD:																	//Load Mode Register
				next_state      = INIT_NOP3;
			INIT_NOP3:																	//Nop
				next_state      = INIT_FIN;
			INIT_FIN:																	//Initilisation complete
				next_state      = INIT_FIN;
			default:
				next_state      = IDLE;
		endcase
	end

	//Output computation 
	always_comb begin
		idle_flag = 1;
		nop1_flag = 1;
		pre_flag = 1;
		ref_flag = 1;
		nop2_flag = 1;
		load_flag = 1;
		nop3_flag = 1;
		fin_flag = 1;
		gpio_ref_cycles = 1;
		gpio_init_begin_counter = 1;
		case(state)
			default:
				begin
					command             =  CMD_NOP;
					address             =  13'b0000000000000;   
					bank                =  2'b00;
					ready               =  1'b0;
					ctr_reset           =  1'b1;
				end
			IDLE:
			begin            
				command             =  CMD_NOP;
				address             =  13'b0000000000000;   
				bank                =  2'b00;
				ready               =  1'b0;
				idle_flag			= 1'b1;
				ctr_reset           =  1'b1;
			end
			INIT_NOP1:
			begin            
				command             =  CMD_NOP;
				address             =  13'b0000000000000;   
				bank                =  2'b00;
				ready               =  1'b0;
				nop1_flag			= 1'b1;
				ctr_reset           =  1'b0;
			end
			INIT_PRE:
			begin
				command             =  CMD_PALL;
				address             =  13'b0010000000000;   
				bank                =  2'b11;					//All banks
				ready               =  1'b0;
				pre_flag			= 1'b1;
				ctr_reset           =  1'b1;						//Reset the counter
			end
			INIT_REF:
			begin
				command             =  CMD_REF;
				address             =  13'b0000000000000;   
				bank                =  2'b00;
				ready               =  1'b0;
				ref_flag			= 1'b1;
				ctr_reset           =  1'b0;
			end
			INIT_NOP2:
			begin
				command             =  CMD_NOP;
				address             =  13'b0000000000000;   
				bank                =  2'b00;
				ready               =  1'b0;
			   	nop2_flag			= 1'b1;
				ctr_reset           =  1'b0; 
			end
			INIT_LOAD:
			begin
				command             =  CMD_MRS;				//Load the mode register
				bank                =  2'b00;    
				address             =  13'b0000000100011;
				ready               =  1'b0;
				load_flag			= 1'b1;
				ctr_reset           =  1'b0;
			end
			INIT_NOP3:
			begin
				command             =  CMD_NOP;
				bank                =  2'b00;    
				address             =  13'b0000000000000; 
				ready               =  1'b0;
				nop3_flag			= 1'b1;
				ctr_reset           =  1'b0;
			end
			INIT_FIN:
			begin
				command             =  CMD_NOP;
				bank                =  2'b00;    
				address             =  13'b0000000000000; 
				ready               =  1'b1;
				fin_flag			= 1'b1;
				ctr_reset           =  1'b0;
			end
		endcase
	end

endmodule
