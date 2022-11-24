module lab2_2(
    input clk,
    input rst,
    input carA,
    input carB,
    output reg [2:0] lightA,
    output reg [2:0] lightB);
    parameter GREEN = 3'b001;
    parameter YELLOW = 3'b010;
    parameter RED = 3'b100;
    reg [2:0] next_lightA, next_lightB;
    reg sec2_A, sec2_B, next_sec2_A, next_sec2_B;

    // FF update
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            lightA <= GREEN;
            lightB <= RED;
            sec2_A <= 1'b0;
            sec2_B <= 1'b0;
        end
        else begin
            lightA <= next_lightA;
            lightB <= next_lightB;
            sec2_A <= next_sec2_A;
            sec2_B <= next_sec2_B;
        end
    end
    // next_lightA
    always @* begin
        next_lightA = GREEN;
        case(lightA)
            GREEN: if(!carA && carB && sec2_A) next_lightA = YELLOW;
            YELLOW: next_lightA = RED;
            RED: if(lightB != YELLOW) next_lightA = RED;
        endcase
    end
    // next_lightB
    always @* begin
        next_lightB = RED;
        case(lightB)
            GREEN: begin
                if(carA && !carB && sec2_B) next_lightB = YELLOW;
                else next_lightB = GREEN;
            end
            RED: if(lightA == YELLOW) next_lightB = GREEN;
        endcase
    end
    // next_sec2_A
    always @* begin
        next_sec2_A = 1'b0;
        case(sec2_A)
            1'b0: if(lightA == GREEN) next_sec2_A = 1'b1;
            1'b1: if(lightA != YELLOW) next_sec2_A = 1'b1;
        endcase
    end
    // next_sec2_B
    always @* begin
        next_sec2_B = 1'b0;
        case(sec2_B)
            1'b0: if(lightB == GREEN) next_sec2_B = 1'b1;
            1'b1: if(lightB != YELLOW) next_sec2_B = 1'b1;
        endcase
    end
endmodule