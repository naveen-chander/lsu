`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.12.2020 00:54:47
// Design Name: 
// Module Name: lsu_wrapper
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


module lsu_wrapper(
input		  clk 			,
input         reset 		,
input		  start			,
input [31:0]  RS1			,  
input [31:0]  RS2			,  
input [11:0]  IMM			,
input [1 :0]  SEW			,
input [1 :0]  EEW			,
input [2 :0]  LMUL			,
input [1:0]   I_TYPE	    ,
input [31:0]  V_DATA_WR     ,
input [31:0]  V_OFFSET      ,
input         D_CS 		    ,
input         D_WE 	        ,
output        ILLEGAL       ,
output        DONE          ,
output [31:0] DATA_RD       );


endmodule

lsu lsu_vhd(
	.clk 		(clk 		),		
	.reset 		(reset 		),
	.start		(start		),		
	.RS1		(RS1		),		
	.RS2		(RS2		),		
	.IMM		(IMM		),		
	.SEW		(SEW		),		
	.EEW		(EEW		),		
	.LMUL		(LMUL		),		
	.I_TYPE	    (I_TYPE	    ),
	.V_DATA_WR  (V_DATA_WR  ),      
	.V_OFFSET   (V_OFFSET   ),      
	.D_CS 		(D_CS 		),        
	.D_WE 	    (D_WE 	    ),        
	.ILLEGAL    (ILLEGAL    ),      
	.DONE       (DONE       ),      
	.DATA_RD    (DATA_RD    )
		);
endmodule