//	Modified from the work from https://github.com/Arkowski24/sdram-controller
// Simple SDRAM Write module 
// The module is built using FSM to perform the Write operation to SDRAM after initilisation

module sdram_write(
	input logic                       iclk,
	input logic                       ireset,
	input logic                       ireq,	//Request signal to initialize the memory
	input logic                       ienb,	//Enable signal to start the initialization
	output logic                      ofin,	//Acknowledgment signal to indicate to other modules, 
													//when initialization is done
	input logic           [12:0]      irow,
	input logic            [9:0]      icolumn,
	input logic            [1:0]      ibank,
	input logic 		   [15:0]		idata,
	
	output logic		          		DRAM_CLK,
	output logic		          		DRAM_CKE,
	output logic  	    	[12:0]		DRAM_ADDR,
	output logic		     [1:0]		DRAM_BA,
	output logic		          		DRAM_CAS_N,
	output logic		          		DRAM_CS_N,
	output logic		          		DRAM_RAS_N,
	output logic		          		DRAM_WE_N,
	output logic		          		DRAM_LDQM,
	output logic		          		DRAM_UDQM,
	output logic 		    [15:0]		DRAM_DQ
);
//=======================================================
//  REG/WIRE declarations
//=======================================================
	logic      [2:0]  state       ;
	logic      [2:0]  next_state;
	logic      [3:0]  command     ;		//Command register to be sent to SDRAM
	logic     [12:0]  address     ;	//Address register
	logic      [1:0]  bank        ;	//Bank register
	logic      [1:0]  dqm         ;	//Masking registers
	logic    [15:0]  data        ;	//Data to write
	logic             ready       ;
	logic      [7:0]  counter     ;
	logic             ctr_reset   ;
	logic    data_count;

// STATES - State
parameter 			IDLE      = 3'b000;
parameter 		    WRIT_ACT = 3'b001;
parameter           WRIT_NOP1  = 3'b010;
parameter           WRIT_WRITE  = 3'b011;
parameter           WRIT_WRITING = 3'b100;
parameter           WRIT_NOP2 = 3'b101;
parameter           WRIT_FIN = 3'b110;         
			  
//Commands send to SDRAM
	parameter CMD_NOP = 4'b0111;
	parameter CMD_BACT = 4'b0011;		//Bank Active
	parameter CMD_WRIT = 4'b0100;		//Write

	assign ofin                                             = ready;

	assign DRAM_ADDR                                        = ienb ? address        : 13'bz;
	assign DRAM_BA                                          = ienb ? bank           : 2'bz;
	assign {DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N}   = ienb ? command        : 4'bz;
	assign {DRAM_UDQM, DRAM_LDQM}                           = ienb ? dqm            : 2'bz;
	assign DRAM_CLK                                         = ienb ? ~iclk          : 1'bz;
	assign DRAM_CKE                                         = ienb ? 1'b1           : 1'bz;
	assign DRAM_DQ                                          = ienb ? data  				: 16'bz;

	always @(posedge iclk or posedge ctr_reset)
	begin
		 if(ctr_reset)
			  counter <=  8'h0;
		 else
			  counter <=  (counter + 1'b1);
	end

	assign data_count = (counter == 5);

	//State Transition 
	always @(posedge iclk)
	begin
		if(ireset)
			state <=  3'b000;
		else
			state <=  next_state;
	end

	//Next state computation 
	always @(state or ireq or data_count)
	begin
		case(state)
			//IDLE
			IDLE:
				if(ireq)
					next_state   <= WRIT_ACT;
				else
					next_state   <= IDLE;
			//ACTIVE
			WRIT_ACT:
				next_state       <= WRIT_NOP1;
			//NOP
			WRIT_NOP1:
				next_state       <= WRIT_WRITE;
			//WRITE
			WRIT_WRITE:
					next_state   <= WRIT_WRITING;                
			//WRITING   										//Keep writing enough data 
			WRIT_WRITING:
				if(data_count)
					next_state   <= WRIT_NOP2;
				else
					next_state   <= WRIT_WRITING;
			//NOP
			WRIT_NOP2:
				next_state       <= WRIT_FIN;
			//NOP - FIN
			WRIT_FIN:
				next_state       <= IDLE;
			default:
				next_state       <= IDLE;
		endcase
	end


	//Output computation 
	always @(posedge iclk)
	begin
		case(state)
			//IDLE
			3'b000:
			begin
				command             <=  CMD_NOP;
				address             <=  13'b0000000000000;
				bank                <=  2'b00;
				dqm                 <=  2'b11;
				ready               <=  1'b0;
				
				ctr_reset           <=  1'b0;
			end
			//ACTIVE
			WRIT_ACT:
			begin
				command             <=  CMD_BACT;
				address             <=  irow;
				bank                <=  ibank;
				dqm                 <=  2'b11;
				data                <=  idata;
				ready               <=  1'b0;
				
				ctr_reset           <=  1'b0;
			end
			//NOP
			WRIT_NOP1:
			begin
				command             <=  CMD_NOP;
				address             <=  13'b0000000000000;   
				bank                <=  2'b00;
				dqm                 <=  2'b11;
				ready               <=  1'b0;
				
				ctr_reset           <=  1'b1;
			end
			//WRITE
			WRIT_WRITE:
			begin
				command             <=  CMD_WRIT;				//Write data 
				address             <=  {3'b001, icolumn};
				bank                <=  ibank;
				dqm                 <=  2'b00;
				ready               <=  1'b0; 
				
				ctr_reset           <=  1'b1;
			end
			//WRITING  
			WRIT_WRITING:
			begin
				command             <=  CMD_NOP;
				address             <=  13'b0000000000000;   
				bank                <=  2'b00;
				dqm                 <=  2'b00;
				ready               <=  1'b0;
				
				ctr_reset           <=  1'b0;
			end
			//NOP
			WRIT_NOP2:
			begin
				command             <=  CMD_NOP;
				address             <=  13'b0000000000000;   
				bank                <=  2'b00;
				dqm                 <=  2'b11;
				ready               <=  1'b0;
				
				ctr_reset           <=  1'b0;
			end
			//NOP - FIN
			WRIT_FIN:
			begin
				command             <=  CMD_NOP;
				address             <=  13'b0000000000000;   
				bank                <=  2'b00;
				dqm                 <=  2'b11;
				ready               <=  1'b1;						//Finish writing
				
				ctr_reset           <=  1'b0;
			end
		endcase
	end

endmodule
