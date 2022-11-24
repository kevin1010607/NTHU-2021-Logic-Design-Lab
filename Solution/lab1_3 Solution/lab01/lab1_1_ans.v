`timescale 1ns/100ps

module lab1_1 (a, b, dir, d);
input [3:0] a;
input [1:0] b;
input dir;
output reg [3:0] d; /*Notice that d can be either reg or
wire. It depends on how you design your module. */
// add your design here  

always@* begin
    if (dir) begin
        d = a >> b;
    end else begin
        d = a << b;
    end
end

endmodule