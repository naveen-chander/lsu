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
input [31:0]  IMM			,
input [1 :0]  SEW			,
input [1 :0]  WIDTH			,
input [2 :0]  LMUL			,
input [1:0]   MOP   	    ,
input         S_VECn        ,
input         MASK          ,
input [31:0]  V_DATA_WR     ,
input [31:0]  V_OFFSET      ,
input         D_CS 		    ,
input         D_WE 	        ,
input         D_RE 	        ,
output        ILLEGAL       ,
output        DONE          ,
output [31:0] DATA_RD       );



lsu lsu_vhd(
	.clk 		(clk 		),		
	.reset 		(reset 		),
	.start		(start		),		
	.RS1		(RS1		),		
	.RS2		(RS2		),		
	.IMM		(IMM		),		
	.SEW		(SEW		),		
	.WIDTH		(WIDTH		),		
	.LMUL		(LMUL		),		
	.MOP	    (MOP	    ),
	.S_VECn	    (S_VECn	    ),
	.MASK	    (MASK	    ),
	.V_DATA_WR  (V_DATA_WR  ),      
	.V_OFFSET   (V_OFFSET   ),      
	.D_CS 		(D_CS 		),        
	.D_WE 	    (D_WE 	    ),        
	.D_RE 	    (D_RE 	    ),        
	.ILLEGAL    (ILLEGAL    ),      
	.DONE       (DONE       ),      
	.DATA_RD    (DATA_RD    )
		);
endmodule