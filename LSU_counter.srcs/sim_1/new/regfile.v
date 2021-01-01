`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.12.2020 01:21:50
// Design Name: 
// Module Name: regfile
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


module regfile(
input           clk,
input           reset,
input           we,
input  [4 :0]   rs1,
input  [4 :0]   rs2,
input  [4 :0]   rd,
input  [31:0]   data_wr,
output [31:0]   data_rd,
output [31:0]   addr_out
);

reg [31:0] reg_array[31:0];
integer i;

always  @(posedge clk)
begin
    if(reset)
        for (i=0;i<32;i=i+1)
            reg_array[i]  <= 32'b0;
    else if(we)
        reg_array[rd]   <= data_wr;
end

assign    data_rd  =   reg_array[rs2];
assign    addr_out =   reg_array[rs1];
    
endmodule
