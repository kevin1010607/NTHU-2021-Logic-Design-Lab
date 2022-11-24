`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/23 19:09:20
// Design Name: 
// Module Name: slow_fist
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


module slow_fist(
    output a_err,
    output b_err,
    input [2:0]a_checked_fist,
    input [2:0]b_checked_fist,
    input reset
    );
    parameter no_fist = 3'b000;

assign a_err = (reset) ? 0:
               ((a_checked_fist == no_fist) & (b_checked_fist != no_fist)) ? 1 : 0;
               
assign b_err = (reset) ? 0:
               ((a_checked_fist != no_fist) & (b_checked_fist == no_fist)) ? 1 : 0;
endmodule
