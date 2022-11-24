`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/08/23 18:02:46
// Design Name: 
// Module Name: lab0
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


module lab0(
    output a_err,
    output b_err,
    output [1:0]tie,
    output [5:0]a_win,
    output [5:0]b_win,
    input [2:0]a_fist,
    input [2:0]b_fist,
    input reset
    );
    wire [2:0]a_checked_fist, b_checked_fist;
    wire a_check_err, b_check_err, a_slow_err, b_slow_err;

assign a_err = (a_check_err | a_slow_err);
assign b_err = (b_check_err | b_slow_err);

fist_check player_a(
    .checked_fist(a_checked_fist),
    .err(a_check_err),
    .fist(a_fist),
    .reset(reset)
    );
    
fist_check player_b(
    .checked_fist(b_checked_fist),
    .err(b_check_err),
    .fist(b_fist),
    .reset(reset)
    );
    
slow_fist s1(
        .a_err(a_slow_err),
        .b_err(b_slow_err),
        .a_checked_fist(a_checked_fist),
        .b_checked_fist(b_checked_fist),
        .reset(reset)
        );    

judge j1(
        .a_win(a_win),
        .b_win(b_win),
        .tie(tie),
        .a_checked_fist(a_checked_fist),
        .b_checked_fist(b_checked_fist),
        .reset(reset)
        );

    
endmodule

