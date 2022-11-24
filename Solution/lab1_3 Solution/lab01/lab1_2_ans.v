`timescale 1ns/100ps

module lab1_2 (a, b, aluctr ,d);
input [3:0] a;
input [1:0] b;
input [1:0] aluctr; 
output reg [3:0] d; /*Notice that d can be either reg or
wire. It depends on how you design your module. */
// add your design here

wire [3:0] d_shift;

lab1_1 shifter(a, b, aluctr[0], d_shift);

always@* begin
    if (aluctr == 2'b00) begin
        d = d_shift;
    end else if (aluctr == 2'b01) begin
        d = d_shift;
    end else if (aluctr == 2'b10) begin
        d = a + b;
    end else begin
        d = a - b;
    end
end


endmodule



