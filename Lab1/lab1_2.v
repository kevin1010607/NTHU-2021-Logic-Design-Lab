`timescale 1ns/100ps
module lab1_2(a, b, aluctr, d);
    input [3:0] a;
    input [1:0] b;
    input [1:0] aluctr;
    output reg [3:0] d;

    wire [3:0] s_L, s_R;
    lab1_1 shift_left(.a(a), .b(b), .dir(1'b0), .d(s_L));
    lab1_1 shift_right(.a(a), .b(b), .dir(1'b1), .d(s_R));

    always @* begin
        case(aluctr)
            2'b00: d = s_L;
            2'b01: d = s_R;
            2'b10: d = a+b;
            2'b11: d = a-b;
        endcase
    end
endmodule