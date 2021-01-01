`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: DESE, IISc
// Engineer: V.Naveen Chander
// 
// Create Date: 17.12.2020 01:08:17
// Design Name: LSU Testbench
// Module Name: testbench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testbench();
    
reg		    CLK 		;
reg         RESET 		;
reg		    LSU_START	;
reg		    VREG_START	;
reg [31:0]  IMM			;
reg [1 :0]  SEW			;
reg [1 :0]  EEW			;
reg [2 :0]  LMUL		;
reg [1:0]   MOP 	    ;
reg         S_VECn      ;
reg         MASK        ;
reg         D_CS 		;
reg         D_WE 	    ;
reg         D_RE 	    ;

reg [4:0] 	RS1_SEL;
reg [4:0] 	RS2_SEL;
reg [4:0] 	RD_SEL;

reg [4:0] 	VS1_SEL;
reg [4:0] 	VS2_SEL;
reg [4:0] 	VD_SEL;


wire [31:0]  RS1_DATA	;
wire [31:0]  RS2_DATA	;
wire [31:0]  VS1_DATA   ;
wire [31:0]  VS2_DATA   ;

reg [31:0]  USER_REG_DIN;
reg LSU_USER_SEL;			//Test bench Control Signal to select between User Data and LSU Data for Registers
reg VREG_WE,REG_WE;			//Separate Scalar and Vector Register File Write Enables 
wire        ILLEGAL  ;		//Flagged by LSU for wrong combination of inputs
wire        LSU_DONE ;		//Indicates LSU Operation is complete
wire        VREG_DONE ;		//Indicates Vector Register Read/Write Operation is Complete
wire [31:0] LSU_DOUT  ;		//LSU Data for Register Files
reg  [31:0] LSU_DIN ;
reg [31:0] REG_DIN , VREG_DIN;
reg [1:0] WIDTH;
reg [8:0] nElements;			//No. of elements in the vector register

///////////////////////////////////////////////
///               LSU  Port map             //
lsu_wrapper UUT(
	.clk 			(CLK 		),
	.reset 	    	(RESET 	    ),
	.start	    	(LSU_START	),
	.RS1		    (RS1_DATA	),
	.RS2		    (RS2_DATA	),
	.IMM		    (IMM		),
	.SEW		    (SEW		),
	.WIDTH		    (WIDTH		),
	.LMUL	    	(LMUL	    ),
	.MOP	    	(MOP	    ),
	.S_VECn	    	(S_VECn	    ),
	.MASK	    	(MASK	    ),
	.V_DATA_WR   	(LSU_DIN    ),
	.V_OFFSET    	(VS2_DATA   ),
	.D_CS 	    	(D_CS 	    ),
	.D_WE 	    	(D_WE 	    ),
	.D_RE 	    	(D_RE 	    ),
	.ILLEGAL     	(ILLEGAL    ),
	.DONE        	(LSU_DONE   ),
	.DATA_RD     	(LSU_DOUT   )
	);

///////////////////////////////////////////////
///               Instantiate VRF           //
vec_regfile VREG(
	.clk 		 (CLK 		),
	.reset 		 (RESET 	),
	.start		 (VREG_START),
	.vd			 (VD_SEL	),
	.vs1		 (VS1_SEL	),
	.vs2		 (VS2_SEL	),
	.LMUL		 (LMUL		),
	.SEW		 (SEW       ),
	.DATA_WR	 (VREG_DIN	),
	.WE			 (VREG_WE	),
	.DATA_RD	 (VS1_DATA	),
	.DONE        (VREG_DONE ),
	.DATA_INDEX  (VS2_DATA	)
	);

///////////////////////////////////////////////
///               Instantiate RF             //	
regfile SREG(
	.clk       	(CLK		),
	.reset    	(RESET      ),
	.we        	(REG_WE     ),
	.rs1       	(RS1_SEL    ),
	.rs2       	(RS2_SEL    ),
	.rd       	(RD_SEL     ),
	.data_wr  	(REG_DIN    ), 
	.data_rd   	(RS2_DATA   ),
	.addr_out  	(RS1_DATA   )
	);

//Clk Gen
initial
	CLK= 1'b1;
always
	#5 CLK 	= ~CLK;

// LSU_DATA USER DATA Mux

always @(LSU_USER_SEL,LSU_DOUT,USER_REG_DIN)
begin
	if(LSU_USER_SEL)
		begin
		REG_DIN	= LSU_DOUT;
		VREG_DIN= LSU_DOUT;
		end
	else
		begin
		REG_DIN	= USER_REG_DIN;
		VREG_DIN= USER_REG_DIN;
		end
end

always @(S_VECn,VS1_DATA,RS2_DATA)
begin
    if(S_VECn)
        LSU_DIN =   RS2_DATA;
    else
        LSU_DIN = VS1_DATA;
end
//Initiallize all design inputs
	reg [8:0] i;
	
/////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////
///            Task Definitions                              ///////
/// Task 1. Write Scalar Register   RegWr(rd,val)

task user_regWrite;
	input [ 4:0]	rd;
	input [31:0] 	val;

	begin
        @(posedge CLK);
	#5	LSU_USER_SEL	= 1'b0;		// Select User Mode
		USER_REG_DIN	= val;		// Drive the RegWrite Data Port with USer Provided Value
		RD_SEL			= rd;		//Select the Register to be written
		REG_WE			= 1'b1;		// Register Write Enable Asserted
	#10	REG_WE			= 1'b0;		//De-assert RegWrite Enable
	end
endtask
////////////////////////////////////////////////////////////////////
////   Task 2: Vector Register Write
////	Writes User Data into Vector Register
//      Since the number of elements can get really large, the elements
//      written into Vector Registers are auto generated as 0,1,2,,,,n 
//		depending upon the values of SEW and LMUL
task user_vregWrite;
	input [1:0]	SEW_val;
	input [2:0]	LMUL_val;
	input [4:0]	vd_val;
	
	begin
    @(posedge CLK);
	#5 LSU_USER_SEL	= 1'b0;		     // Select User Mode 
	    if(LMUL_val < 0)
		  nElements	= (256/(8*(2**SEW_val))) >> (-LMUL_val);	// Total number of elemnts to be loaded into the VRF
		else  
		  nElements	= (256/(8*(2**SEW_val))) << (LMUL_val);	// Total number of elemnts to be loaded into the VRF
		SEW			=	SEW_val;	//Assign element width
		LMUL		=	LMUL_val;	//Vector length multiplier
		VD_SEL		=	vd_val;		//Designation register
		VREG_WE		= 	1'b1;		//Initiate Vector Reg write
		VREG_START 	= 	1'b1;		// Start  Storing into Vec Regs
		
		if(nElements != 1)
		  for(i=0;i<nElements;i=i+1)
		      begin
			     USER_REG_DIN	=	nElements - i - 1;
             	// if nElements = 255 => Data will go as 0xFF 0xFE 0xFd ...
		      #10 VREG_START 		= 'b1;					//1 clock delay
	       end
	    else
		  USER_REG_DIN	=	32'hFACECAFE;  
    VREG_START 		= 1'b0;
    VREG_WE			= 1'b0;
    end
endtask

// 3. Task 3: Load Scalar from Data Memory
task load;
    input [4:0] RS1_val;
    input integer IMM_val;
    input [4:0] RD_val;
    begin
        @(posedge CLK);
    #5  S_VECn          = 1'b1;
        LSU_USER_SEL	= 1'b1;		// Select LSU Mode
        D_CS            = 1'b1;     //
        D_RE            = 1'b1;
        D_WE            = 1'b0;
        RS1_SEL         = RS1_val;
        RD_SEL          = RD_val;
        IMM             = IMM_val;
    #10 D_CS            = 1'b0;
        D_RE            = 1'b0;
        D_WE            = 1'b0;
    #10 REG_WE          = 1'b1;
    #10 REG_WE          = 1'b0;
    end
endtask

// 4. Task 4: Load vector from Memory 
task vload;
    input [4:0] RS1_val;
    input [4:0] VD_val;
    input [1:0] SEW_val;
    input [2:0] LMUL_val;
    input [1:0] WIDTH_val;
    input [1:0] MOP_val;
    begin
        @(posedge CLK);
    #5	WIDTH 			= (WIDTH_val);
        MOP             = MOP_val;
        SEW             = (SEW_val);
	    RS1_SEL			= RS1_val;
		LMUL			= (LMUL_val);
	    VD_SEL			= VD_val;
	    S_VECn          = 1'b0;    //Enter Vector Mode
	    LSU_USER_SEL	= 1'b1;	//LSU To Write Data to Registers
	    D_CS			= 1'b1;		
	    D_RE			= 1'b1;	
	    LSU_START       = 1'b1;
    #20 VREG_START		= 1'b1;
        VREG_WE         = 1'b1;
     // Wait for Done Signal to arrive
    @(posedge LSU_DONE);
        LSU_START 		= 1'b0;
    @(posedge VREG_DONE);
        D_WE			= 1'b0;
        D_RE			= 1'b0;
        D_CS			= 1'b0;    	
	    VREG_START 		= 1'b0;
	#20 VREG_WE         = 1'b0;   
    end
endtask

// Task 5: Store Scalar into Memory
task store;
    input [4:0] RS1_val;
    input integer IMM_val;
    input [4:0] RS2_val;
    begin
        @(posedge CLK);
    #5  S_VECn          = 1'b1;
        LSU_USER_SEL	= 1'b1;		// Select LSU Mode
        D_CS            = 1'b1;     //
        D_RE            = 1'b0;
        D_WE            = 1'b1;
        RS1_SEL         = RS1_val;
        RS2_SEL         = RS2_val;
        IMM             = IMM_val;
    #10 D_CS            = 1'b0;
        D_WE            = 1'b0;
        D_RE            = 1'b0;
    end
endtask    

// Task 6: Store Vector into Memory
task vstore;
    input [4:0] RS1_val;
    input [4:0] VS1_val;
    input [4:0] VS2_val;
    input [1:0] SEW_val;
    input [2:0] LMUL_val;
    input [1:0] WIDTH_val;
    input [1:0] MOP_val;
    begin
        @(posedge CLK);
    #5  S_VECn          = 1'b0;
        LSU_USER_SEL	= 1'b1;		// Select LSU Mode
	    LMUL			= (LMUL_val);
	    SEW				= (SEW_val);
	    VREG_WE			= 1'b0;
    	WIDTH 			= (WIDTH_val);
        MOP             = MOP_val;
        SEW             = SEW_val;
	    VS1_SEL			= VS1_val;
	    VS2_SEL			= VS2_val;
    	D_CS			= 1'b1;		
	    D_WE			= 1'b1;	
	    LSU_START       = 1'b1;
    #10	VREG_START		= 1'b1;
    
        @(posedge VREG_DONE);
    	LSU_START 		= 1'b0;
	    VREG_START 		= 1'b0;
	    D_WE			= 1'b0;
	    D_CS			= 1'b0;
	    D_RE			= 1'b0;
    end
endtask

initial 
begin

	RESET  		= 1'b1;
	LSU_START	= 1'b0;		
	VREG_START	= 1'b0;		
	IMM			= 32'b0;
	SEW			= 2'b0;
	EEW			= SEW;		//Maintain this throughout unless necessary
	LMUL		= 3'b0;
	MOP    	    = 2'b0;    //Unit Stride
	S_VECn      = 1'b1;    //Scalar Access
	MASK        = 1'b1;    //No Mask
	D_CS 		= 1'b0;	
	D_WE		= 1'b0;
	D_RE		= 1'b0;
	RS1_SEL		= 5'B0;
	RS2_SEL		= 5'B0;
	VS1_SEL		= 5'B0;
	VS2_SEL		= 5'B0;
	RD_SEL		= 5'B0;
	VD_SEL		= 5'B0;
	LSU_USER_SEL = 1'b0;
	USER_REG_DIN   = 32'b0;
	REG_WE       = 1'b0;
	VREG_WE      = 1'b0;
	WIDTH        = 2'b10;
			
#105	
	RESET		=	1'b0		;
//////////////////////////////////////////////////////
//                  Test Cases                    ////
//--------------------------------------------------//
// TEST CASE 1:  Scalar Store followed by Load
//  Addr : 0x100;   Data : 0xAA55AA55
#50 user_regWrite(5'b10,32'hAA55AA55);	// r2<-0xAA55AA55
#10 user_regWrite(5'b1,32'h100);		// r1<-0x100
#10 store(5'b1,0,5'b10);				//sw r2,(r1)
#20 load(5'b1,0,5'b11);	   				//lw r3,(r1)

//--------------------------------------------------//
// TEST CASE 2:  Vector Unit Stride Store followed by Load
// Base Addr : 0x200; 
// SEW :32 bit ; LMUL = 1
// Load v0 with Data->Store at 0x200->Load it back to v1

#90 user_vregWrite(2'b10,3'b0,5'b0);
#10 user_regWrite(5'b1,32'h200);
#10	vstore(5'b1,5'b0,5'b1,2'b10,3'b0,2'b10,2'b0);
#30 vload(5'b1,5'b1,2'b10,3'b0,2'b10,2'b0);


//--------------------------------------------------//
// TEST CASE 3:  Vector Unit Stride Store followed by Load
// Base Addr : 0x280; 
// SEW :32 bit ; LMUL = 1/8
// Load v2 with Data->Store at 0x280->Load it back to v3

#90 user_vregWrite(2'b10,-3,5'b0);
#10 user_regWrite(5'b1,32'h200);
#10	vstore(5'b1,5'b0,5'b1,2'b10,-3,2'b10,2'b0);
#30 vload(5'b1,5'b1,2'b10,-3,2'b10,2'b0);

#50 $finish;
end
endmodule