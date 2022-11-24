`define NONE 2'b00
`define TOUCH 2'b01
`define OVERLAP_EDGE 2'b10
`define OVERLAP_MID 2'b11
module lab3_3(
    input clk,
    input rst,
    input en,
    input speed,
    output wire [15:0] led);
    wire clk_23, clk_25, clk_24, clk_26, clk_dir;
    wire [1:0] collide_type;
    wire [15:0] Mr1, Mr3;
    reg [15:0] Mr1_1, Mr1_0, Mr3_1, Mr3_0, next_Mr1, next_Mr3;
    reg dir, next_dir;
    reg [25:0] count, next_count;
    parameter RIGHT = 1'b0;
    parameter LEFT = 1'b1;
    // collide_type
    Collide_Type m(.Mr1(Mr1), .Mr3(Mr3), .type(collide_type));
    // count
    always @(posedge clk, posedge rst) begin
        if(rst == 1'b1) count <= 1'b0;
        else count <= next_count;
    end
    // next_count
    always @* begin
        next_count = count+1'b1;
    end
    // clk_23, clk_25, clk_24, clk_26, clk_dir
    assign clk_23 = count[22];
    assign clk_25 = count[24];
    assign clk_24 = count[23];
    assign clk_26 = count[25];
    assign clk_dir = speed?clk_24:clk_23;
    // dir
    always @(posedge clk_dir, posedge rst) begin
        if(rst == 1'b1) dir <= LEFT;
        else dir <= next_dir;
    end
    // Mr1_1, Mr1_0, Mr3_1, Mr3_0
    always @(posedge clk_24, posedge rst) begin
        if(rst == 1'b1) Mr1_1 <= 16'b1000_0000_0000_0000;
        else Mr1_1 <= next_Mr1;
    end
    always @(posedge clk_23, posedge rst) begin
        if(rst == 1'b1) Mr1_0 <= 16'b1000_0000_0000_0000;
        else Mr1_0 <= next_Mr1;
    end
    always @(posedge clk_26, posedge rst) begin
        if(rst == 1'b1) Mr3_1 <= 16'b0000_0000_0000_0111;
        else Mr3_1 <= next_Mr3;
    end
    always @(posedge clk_25, posedge rst) begin 
        if(rst == 1'b1) Mr3_0 <= 16'b0000_0000_0000_0111;
        else Mr3_0 <= next_Mr3;
    end
    // Mr1, Mr3
    assign Mr1 = speed?Mr1_1:Mr1_0;
    assign Mr3 = speed?Mr3_1:Mr3_0;
    // led
    assign led = Mr1|Mr3;
    // next_Mr1
    always @* begin
        next_Mr1 = Mr1;
        if(en == 1'b1) next_Mr1 = move(Mr1, dir, collide_type);
    end
    // next_Mr3
    always @* begin
        next_Mr3 = Mr3;
        if(en == 1'b1) next_Mr3 = move(Mr3, LEFT, `NONE);
    end
    // next_dir
    always @* begin
       next_dir = dir;
       if(en == 1'b1) begin
            if(collide_type != `NONE) next_dir = dir^1;
       end 
    end
    // function move
    function [15:0] move;
        input [15:0] led;
        input dir;
        input [1:0] type;
        begin
            case(type)
                `NONE: move = (dir==RIGHT)?{led[0], led[15:1]}:{led[14:0], led[15]};
                `TOUCH: move = (dir==RIGHT)?{led[14:0], led[15]}:{led[0], led[15:1]};
                `OVERLAP_EDGE: move = (dir==RIGHT)?{led[13:0], led[15:14]}:{led[1:0], led[15:2]};
                `OVERLAP_MID: move = (dir==RIGHT)?{led[12:0], led[15:13]}:{led[2:0], led[15:3]};
            endcase
        end
    endfunction
endmodule

module Collide_Type(
    input [15:0] Mr1,
    input [15:0] Mr3,
    output reg [1:0] type);
    wire test0, test1, test2;
    assign test0 = ^(Mr1|Mr3);
    assign test1 = ^({Mr1[0], Mr1[15:1]}|Mr3);
    assign test2 = ^({Mr1[14:0], Mr1[15]}|Mr3);
    always @* begin
        type = `NONE;
        case({test0, test1, test2})
            3'b000: type = `NONE;
            3'b001: type = `TOUCH;
            3'b010: type = `TOUCH;
            3'b101: type = `OVERLAP_EDGE;
            3'b110: type = `OVERLAP_EDGE;
            3'b111: type = `OVERLAP_MID;
        endcase
    end
endmodule
