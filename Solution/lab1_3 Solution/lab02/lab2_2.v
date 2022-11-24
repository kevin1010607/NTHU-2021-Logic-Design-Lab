`timescale 1ns / 1ps

module lab2_2(
    input clk, 
    input rst, 
    input carA, 
    input carB,
    output reg [2:0] lightA, 
    output reg [2:0] lightB);

    reg [2:0] next_state, state;
    
    always @(posedge clk, posedge rst) begin
        if(rst==1) state <= 3'd5;
        else state <= next_state;
    end 
    
    always @* begin
        case(state)
            3'd0: begin
                {lightA, lightB} = 6'b001100;
                if(carB==1'b1&&carA==1'b0) next_state = 3'd1;
                else next_state = state;
            end
            3'd1: begin
                {lightA, lightB} = 6'b010100;
                next_state = 3'd2;
            end
            3'd2: begin 
                {lightA, lightB} = 6'b100001;
                next_state = 3'd3;
            end
            3'd3: begin
                {lightA, lightB} = 6'b100001;
                if(carA==1'b1&&carB==1'b0) next_state = 3'd4;
                else next_state = state;
            end
            3'd4: begin
                {lightA, lightB} = 6'b100010;
                next_state = 3'd5;
            end
            3'd5: begin
                {lightA, lightB} = 6'b001100;
                next_state = 3'd0;
            end    
        endcase
    end
    
endmodule
