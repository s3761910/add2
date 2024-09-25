//	Modified from the work from https://github.com/Arkowski24/sdram-controller
// Simple SDRAM Controller module 
// The module is built using FSM with three major states: Initialize, Read and Write
// Read and Write have multiple sub-states

module sdram_controller(
	input logic 		          		iclk,
	input logic 		          		ireset,

	input logic                       iwrite_req,
	input logic           [21:0]      iwrite_address,
	input logic          [15:0]      iwrite_data,
	output logic                      owrite_ack,
	
	input logic                       iread_req,
	input logic           [21:0]      iread_address,
	output logic         [15:0]      oread_data,
	output logic                      oread_ack,
	
	//////////// SDRAM //////////
	output logic		    [12:0]		DRAM_ADDR,
	output logic		     [1:0]		DRAM_BA,
	output logic		          		DRAM_CAS_N,
	output logic		          		DRAM_CKE,
	output logic		          		DRAM_CLK,
	output logic		          		DRAM_CS_N,
	// inout logic	  		    [15:0]		DRAM_DQ,
	output logic 				[15:0] 		dq_read,
	output logic 				[15:0] 		dq_write,
	output logic 				[15:0] 		dq_init,
	output logic		          		DRAM_LDQM,
	output logic		          		DRAM_RAS_N,
	output logic		          		DRAM_UDQM,
	output logic		          		DRAM_WE_N,

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
);

//=======================================================
//  REG/WIRE declarations
//=======================================================
	logic      [3:0]  state       ;
	logic      [3:0]  next_state  ;
	logic      [2:0]  mul_state   ;

	logic             read_ack    ;
	logic             write_ack   ;

	//Next opperation priority - 0  1              next_prior 

	//SDRAM INITLIZE MODULE
	logic            init_ireq   ;
	logic            init_ienb;
	logic            init_fin;
	logic 				next_prior;
	//SDRAM WRITE MODULE
	logic            write_ireq  ;
	logic            write_ienb;
	logic    [12:0]  write_irow;
	logic     [9:0]  write_icolumn;
	logic     [1:0]  write_ibank;
	logic            write_fin;

	//SDRAM READ MODULE
	logic             read_ireq   ;
	logic            read_ienb;
	logic    [12:0]  read_irow;
	logic     [9:0]  read_icolumn;
	logic     [1:0]  read_ibank;
	logic            read_fin;
	// logic firs_t;

// logic	  		    [15:0]		DRAM_DQ;
assign dq_read = iread_req? dq_write:dq_read;
// assign dq_read = dq_write;

// STATES - State
parameter 			INIT_START      = 4'b0000;
parameter			INIT_FIN = 4'b0001;
parameter           IDLE  = 4'b0010;
parameter           WRIT_START   = 4'b0011;
parameter           WRIT_FIN = 4'b0100;
parameter           WRIT_ACK = 4'b0101;
parameter           READ_START = 4'b0110;
parameter           READ_FIN  = 4'b0111;			  
parameter			READ_ACK  = 4'b1000;			  

// STATES - Mul State
parameter 			INIT = 3'b001;
parameter			WRIT = 3'b010;
parameter           READ = 3'b100;			  
			  			  
//=======================================================
//  Structural coding
//=======================================================
	assign {write_ibank, write_irow, write_icolumn} = {iwrite_address, 3'b0};
	assign {read_ibank, read_irow, read_icolumn}    = {iread_address, 3'b0};

	assign owrite_ack                               = write_ack;
	assign oread_ack                                = read_ack;

	//Generate enable signals for each module
	assign {read_ienb, write_ienb, init_ienb}       = mul_state;		

	//State Transition
	always_ff @(posedge iclk)
	begin
		if(ireset == 1'b1) begin
			state <=  INIT_START;
		end
		else begin
			state <=  next_state;
		end
	end

	//Next state computation
	always_comb	begin
		// firs_t = 1;
		case(state)
			//Init States
			INIT_START:									//Start initiliasation
				next_state      = INIT_FIN;
			INIT_FIN:									//End initiliasation
				if(init_fin)
					next_state  = IDLE;
				else
					next_state  = INIT_FIN;
					
			//Idle State
			IDLE:		
				begin
					// if (firs_t) begin
					// 	firs_t = 0;
					// end
					if(next_prior)
					begin
						if(iread_req)
							next_state  = READ_START;
						else if(iwrite_req)
							next_state  = WRIT_START;
						else
							next_state  = IDLE;
					end
					else
					begin
						if(iwrite_req)
							next_state  = WRIT_START;
						else if(iread_req)
							next_state  = READ_START;
						else
							next_state  = IDLE;
					end
				end									//Idle to wait for read or write
			
			//Write States
			WRIT_START:									//Start to write
				next_state      = WRIT_FIN;    
			WRIT_FIN:									//Writing is complete
				if(write_fin)
					next_state  = WRIT_ACK;
				else
					next_state  = WRIT_FIN;	
			WRIT_ACK:									//Acknowlege that Writing is done
				next_state      = IDLE;
				
			//Read States        `
			READ_START:									//Start to read	
				next_state      = READ_FIN;
			READ_FIN:									//Reading is complete
				if(read_fin)
					next_state  = READ_ACK;
				else
					next_state  = READ_FIN;
			READ_ACK:									//Acknowlege that Reading is done
				next_state      = IDLE;
			default:
				next_state      = INIT_START;
		endcase
	end

	// Output computation
	always_comb	begin
		case(state)
			default: begin
				
				init_ireq       = 1'b1;
				write_ireq      = 1'b0;
				read_ireq       = 1'b0;
				
				write_ack       = 1'b0;
				read_ack        = 1'b0;
				
				mul_state       = INIT;
				next_prior      = 1'b0;
			end
			//Init States
			INIT_START:
			begin            
				init_ireq       = 1'b1;
				write_ireq      = 1'b0;
				read_ireq       = 1'b0;
				
				write_ack       = 1'b0;
				read_ack        = 1'b0;
				
				mul_state       = INIT;
				next_prior      = 1'b0;
			end
			INIT_FIN:
			begin            
				init_ireq       = 1'b0;
				write_ireq      = 1'b0;
				read_ireq       = 1'b0;
				
				write_ack       = 1'b0;
				read_ack        = 1'b0;
				
				mul_state       = INIT;
				next_prior      = 1'b0;
			end
			
			//Idle State
			IDLE:
			begin            
				init_ireq       = 1'b0;
				write_ireq      = 1'b0;
				read_ireq       = 1'b0;
				
				write_ack       = 1'b0;
				read_ack        = 1'b0;
				
				mul_state       = INIT;
				next_prior      = 1'b0;
			end
			
			//Write States
			WRIT_START:
			begin            
				init_ireq       = 1'b0;
				write_ireq      = 1'b1;
				read_ireq       = 1'b0;
				
				write_ack       = 1'b0;
				read_ack        = 1'b0;
				
				mul_state       = WRIT;
				next_prior      = 1'b0;
			end
			
			WRIT_FIN:
			begin            
				init_ireq       = 1'b0;
				write_ireq      = 1'b0;
				read_ireq       = 1'b0;
				
				write_ack       = 1'b0;
				read_ack        = 1'b0;
				
				mul_state       = WRIT;
				next_prior      = 1'b0;
			end
			WRIT_ACK:
			begin            
				init_ireq       = 1'b0;
				write_ireq      = 1'b0;
				read_ireq       = 1'b0;
				
				write_ack       = 1'b1;
				read_ack        = 1'b0;
				
				mul_state       = WRIT;
				next_prior      = 1'b1;
			end
			
			//Read States
			READ_START:
			begin            
				init_ireq       = 1'b0;
				write_ireq      = 1'b0;
				read_ireq       = 1'b1;
				
				write_ack       = 1'b0;
				read_ack        = 1'b0;
				
				mul_state       = 3'b100;
				next_prior      = 1'b1;
			end
			READ_FIN:
			begin            
				init_ireq       = 1'b0;
				write_ireq      = 1'b0;
				read_ireq       = 1'b0;
				
				write_ack       = 1'b0;
				read_ack        = 1'b0;
				
				mul_state       = 3'b100;
				next_prior      = 1'b1;
			end
			READ_ACK:
			begin            
				init_ireq       = 1'b0;
				write_ireq      = 1'b0;
				read_ireq       = 1'b0;
				
				write_ack       = 1'b0;
				read_ack        = 1'b1;
				
				mul_state       = 3'b100;
				next_prior      = 1'b0;
			end
		endcase
	end

	//Instantiate sub modules 

	sdram_initialize sdram_init (
		.iclk(iclk),
		.ireset(ireset),
		
		.ireq(init_ireq),
		.ienb(init_ienb),
		
		.ofin(init_fin),
		
		.DRAM_ADDR(DRAM_ADDR),
		.DRAM_BA(DRAM_BA),
		.DRAM_CAS_N(DRAM_CAS_N),
		.DRAM_CKE(DRAM_CKE),
		.DRAM_CLK(DRAM_CLK),
		.DRAM_CS_N(DRAM_CS_N),
		.DRAM_DQ(dq_init),
		.DRAM_LDQM(DRAM_LDQM),
		.DRAM_RAS_N(DRAM_RAS_N),
		.DRAM_UDQM(DRAM_UDQM),
		.DRAM_WE_N(DRAM_WE_N),
		.idle_flag(idle_flag),
		.nop1_flag(nop1_flag),
		.pre_flag(pre_flag),
		.ref_flag(ref_flag),
		.nop2_flag(nop2_flag),
		.load_flag(load_flag),
		.nop3_flag(nop3_flag),
		.fin_flag(fin_flag),
		.gpio_ref_cycles(gpio_ref_cycles),
		.gpio_init_begin_counter(gpio_init_begin_counter)
	);

	sdram_write sdram_write (
		.iclk(iclk),
		.ireset(ireset),
		
		.ireq(write_ireq),
		.ienb(write_ienb),
		
		.irow(write_irow),
		// .icolumn(write_icolumn),
		.icolumn(100011),
		.ibank(write_ibank),
		.idata(iwrite_data),
		.ofin(write_fin),
		
		.DRAM_ADDR(DRAM_ADDR),
		.DRAM_BA(DRAM_BA),
		.DRAM_CAS_N(DRAM_CAS_N),
		.DRAM_CKE(DRAM_CKE),
		.DRAM_CLK(DRAM_CLK),
		.DRAM_CS_N(DRAM_CS_N),
		.DRAM_DQ(dq_write),
		.DRAM_LDQM(DRAM_LDQM),
		.DRAM_RAS_N(DRAM_RAS_N),
		.DRAM_UDQM(DRAM_UDQM),
		.DRAM_WE_N(DRAM_WE_N)
	);

	sdram_read sdram_read (
		.iclk(iclk),
		.ireset(ireset),
		
		.ireq(read_ireq),
		.ienb(read_ienb),
		
		.irow(read_irow),
		.icolumn(read_icolumn),
		.ibank(read_ibank),
		.odata(oread_data),
		.ofin(read_fin),
		
		.DRAM_ADDR(DRAM_ADDR),
		.DRAM_BA(DRAM_BA),
		.DRAM_CAS_N(DRAM_CAS_N),
		.DRAM_CKE(DRAM_CKE),
		.DRAM_CLK(DRAM_CLK),
		.DRAM_CS_N(DRAM_CS_N),
		.DRAM_DQ(dq_read),
		.DRAM_LDQM(DRAM_LDQM),
		.DRAM_RAS_N(DRAM_RAS_N),
		.DRAM_UDQM(DRAM_UDQM),
		.DRAM_WE_N(DRAM_WE_N)
	);

endmodule
