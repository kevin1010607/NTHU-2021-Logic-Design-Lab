`timescale 1ns/100ps
module lab1_1(a, b, dir, d);
    input [3:0] a;
    input [1:0] b;
    input dir;
    output reg [3:0] d;
    
    always @* begin
        d = (dir==1'b0)?(a<<b):(a>>b);
    end
endmodule