`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/09/09 13:53:00
// Design Name: 
// Module Name: lab0_t
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


module lab0_t;
    
    reg  [2:0]a_fist;
    reg  [2:0]b_fist;
    reg  reset;
    wire a_err, b_err;
    wire [5:0]a_win;
    wire [5:0]b_win;
    wire [1:0]tie;
    
    lab0 game(.a_err(a_err),
              .b_err(b_err),
              .tie(tie),
              .a_win(a_win),
              .b_win(b_win),
              .a_fist(a_fist),
              .b_fist(b_fist),
              .reset(reset));

    initial begin
        #0 a_fist = 3'b000; b_fist = 3'b000;  reset = 1'b0;
        #64 $finish;
    end
    
    always #1 b_fist = b_fist + 1;
    always #8 a_fist = a_fist + 1;
    
endmodule
