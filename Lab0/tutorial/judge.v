`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/23 18:28:16
// Design Name: 
// Module Name: judge_round1
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


module judge(
    output [5:0]a_win,
    output [5:0]b_win,
    output [1:0]tie,
    input  [2:0]a_checked_fist,
    input  [2:0]b_checked_fist,
    input  reset
    );


parameter scissors = 3'b001;
parameter rock     = 3'b010;
parameter paper    = 3'b100;

assign a_win = (reset) ? 6'b0 :
                          ((a_checked_fist == scissors) & (b_checked_fist == paper)) ? 6'b111111:
                          ((a_checked_fist == rock) & (b_checked_fist == scissors)) ? 6'b111111:
                          ((a_checked_fist == paper) & (b_checked_fist == rock)) ? 6'b111111:6'b0;

assign b_win = (reset) ? 6'b0 :
                          ((a_checked_fist == scissors) & (b_checked_fist == rock)) ? 6'b111111:
                          ((a_checked_fist == rock) & (b_checked_fist == paper)) ? 6'b111111:
                          ((a_checked_fist == paper) & (b_checked_fist == scissors)) ? 6'b111111:6'b0;

assign tie = (reset) ? 2'b0 :
             ((a_checked_fist == scissors) & (b_checked_fist == scissors)) ? 2'b11:
             ((a_checked_fist == rock) & (b_checked_fist == rock)) ? 2'b11:
             ((a_checked_fist == paper) & (b_checked_fist == paper)) ? 2'b11:2'b0;                        
    
    
endmodule
