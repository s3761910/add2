//	Modified from the work from https://github.com/Arkowski24/sdram-controller
// Simple SDRAM Read module 
// The module is built using FSM to perform the Read operation to SDRAM after initiliasion 
module sdram_read(
	input logic                      iclk,
	input logic                      ireset,
	input logic                      ireq,	//Request signal to initialize the memory
	input logic                      ienb,	//Enable signal to start the initialization
	output logic                      ofin,	//Acknowledgment signal to indicate to other modules, 
													//when initialization is done
    
	input logic           [12:0]      irow,
	input logic           [9:0]      icolumn,
	input logic           [1:0]      ibank,
	output logic 		 [15:0]		odata,
    
	output logic 		          		DRAM_CLK,
	output logic		          		DRAM_CKE,
	output logic 	   	 [12:0]		DRAM_ADDR,
	output logic		 [1:0]		DRAM_BA,
	output logic		          		DRAM_CAS_N,
	output logic		          		DRAM_CS_N,
	output logic		          		DRAM_RAS_N,
	output logic		          		DRAM_WE_N,
	output logic		          		DRAM_LDQM,
	output logic		          		DRAM_UDQM,
	input logic		    [15:0]		DRAM_DQ
);
//=======================================================
//  REG/WIRE declarations
//=======================================================
	logic      [2:0]  state    ;
	logic      [2:0]  next_state;
	
	logic      [3:0]  command  ;		//Command register to be sent to SDRAM
	logic     [12:0]  address  ;	//Address register
	logic      [1:0]  bank     ;	//Bank register
	logic      [1:0]  dqm      ;	//Masking registers
	
	logic    [15:0]  data     ;	//Data read from the SDRAM

	logic             ready    ;

	logic      [7:0]  counter  ;
	logic             ctr_reset;

	logic    dqm_count;
	logic    data_count;

	
// STATES - State
	parameter IDLE      = 3'b000;
	parameter READ_ACT = 3'b001;
	parameter READ_NOP1  = 3'b010;
	parameter READ_READ   = 3'b011;
	parameter READ_CAS1_NOP = 3'b100;
	parameter READ_CAS2_NOP = 3'b101;
	parameter READ_READING = 3'b110;
	parameter READ_FIN  = 3'b111;			  

	//Commands
	parameter CMD_NOP = 4'b0111;
	parameter CMD_BACT = 4'b0011;		//Bank Active
	parameter CMD_READ = 4'b0101;		//Write

	assign ofin                                             = ready;
	assign odata                                            = data;

	//Pins are pull to High Z if enable is not asserted 
	assign DRAM_ADDR                                        = ienb ? address    : 13'bz;
	assign DRAM_BA                                          = ienb ? bank       : 2'bz;
	assign {DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N}   = ienb ? command    : 4'bz;
	assign {DRAM_UDQM, DRAM_LDQM}                           = ienb ? dqm        : 2'bz;
	assign DRAM_CLK                                         = ienb ? ~iclk      : 1'bz;
	assign DRAM_CKE                                         = ienb ? 1'b1       : 1'bz;

	always_ff @(posedge iclk, posedge ctr_reset)
	begin
		 if(ctr_reset)
			  counter <=  8'h0;
		 else
			  counter <=  (counter + 1'b1);
	end

	//Flags to indicate enough data is read
	assign dqm_count    = (counter < 5);
	assign data_count   = (counter == 7);

	//State Transition 
	always_ff @(posedge iclk)
	begin
		if(ireset == 1'b1)
			state <=  IDLE;
		else
			state <=  next_state;
	end

	//Next state computation 
	always_comb	begin
		case(state)
			//IDLE
			IDLE:
				if(ireq)
					next_state   = READ_ACT;
				else
					next_state   = IDLE;
			//ACTIVE
			READ_ACT:
				next_state       = READ_NOP1;
			//NOP
			READ_NOP1:
				next_state       = READ_READ;
			//READ
			READ_READ:
				next_state       = READ_CAS1_NOP;
			//CAS - 1 NOP 
			READ_CAS1_NOP:
				next_state       = READ_CAS2_NOP;
			//CAS - 2 NOP 
			READ_CAS2_NOP:
				next_state       = READ_READING;
			//READING - 8
			READ_READING:
				if(data_count)									//Keep reading until reaching 8 
					next_state   = READ_FIN;
				else
					next_state   = READ_READING;
			//NOP - FIN
			READ_FIN:
				next_state       = IDLE;
			default:
				next_state       = IDLE;
		endcase
	end

	//Output computation 
	always_comb	begin
		data                =  DRAM_DQ;
		case(state)
			//IDLE
			IDLE:
			begin
				command             =  CMD_NOP;
				address             =  13'b0000000000000;
				bank                =  2'b00;
				dqm                 =  2'b11;
				ready               =  1'b0;
				
				ctr_reset           =  1'b0;
			end
			//ACTIVE
			READ_ACT:
			begin
				command             =  CMD_BACT;			//Bank Active
				address             =  irow;
				bank                =  ibank;
				dqm                 =  2'b11;
				ready               =  1'b0;
				
				ctr_reset           =  1'b0;
			end
			//NOP
			READ_NOP1:
			begin
				command             =  CMD_NOP;
				address             =  13'b0000000000000;   
				bank                =  2'b00;
				dqm                 =  2'b11;
				ready               =  1'b0;
				
				ctr_reset           =  1'b0;
			end
			//READ
			READ_READ:
			begin
				command             =  CMD_READ;			//Read command
				address             =  {3'b001, icolumn};
				bank                =  ibank;
				dqm                 =  2'b11;
				ready               =  1'b0;
				
				ctr_reset           =  1'b0;
			end
			//CAS - 1 NOP 
			READ_CAS1_NOP:
			begin
				command             =  CMD_NOP;
				address             =  13'b0000000000000;   
				bank                =  2'b00;
				dqm                 =  2'b00;
				ready               =  1'b0;
				
				ctr_reset           =  1'b0;
			end
			//CAS - 2 NOP 
			READ_CAS2_NOP:
			begin
				command             =  CMD_NOP;
				address             =  13'b0000000000000;   
				bank                =  2'b00;
				dqm                 =  2'b00;
				ready               =  1'b0;
				
				ctr_reset           =  1'b1;						//Reset counter and start to count the byte to read
			end
			//READING - 8							
			READ_READING:
			begin
				command             =  CMD_NOP;
				address             =  13'b0000000000000;   
				bank                =  2'b00;
				dqm                 =  dqm_count ? 2'b00 : 2'b11;
				data                =  DRAM_DQ;
				ready               =  1'b0;

				
				ctr_reset           =  1'b0;
			end
			//NOP - FIN
			READ_FIN:
			begin
				command             =  CMD_NOP;
				address             =  13'b0000000000000;   
				bank                =  2'b00;
				dqm                 =  2'b11;
				ready               =  1'b1;						//Read is complete
				
				ctr_reset           =  1'b0;
			end
		endcase
	end

endmodule
