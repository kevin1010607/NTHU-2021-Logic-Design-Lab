`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/23 18:09:19
// Design Name: 
// Module Name: fist_check
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


module fist_check(
    output [2:0]checked_fist,
    output err,
    input [2:0]fist,
    input reset
    );
    
assign err = (reset) ? 0 :
             ((fist == 3'b001) | (fist == 3'b010) | (fist == 3'b100) | (fist == 3'b000)) ? 0 : 1;
assign checked_fist= (reset) ? 3'b0 :
                     (err) ? 3'b0 : fist;

endmodule

