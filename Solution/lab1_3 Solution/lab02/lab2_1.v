`timescale 1ns / 1ps

module lab2_1(
    input clk,
    input rst,
    output reg [5:0] out);

    reg dir, next_dir; // 0 for upward, 1 for downward
    reg [5:0] n, next_n, next_out;
    
    always @(posedge clk, posedge rst) begin
        if(rst==1'b1) begin
            dir <= 1'b0;
            n <= 6'd1;
            out <= 6'd0;
        end else begin 
            dir <= next_dir;
            n <= next_n;
            out <= next_out;
        end    
    end

    always @* begin
        case(next_out)
        6'd0: begin
            next_dir = ~dir;
            next_n = 6'd1;
        end
        6'd63: begin
            next_dir = ~dir;
            next_n = 6'd0;
        end
        default: begin
            next_dir = dir;
            next_n = n + 6'd1;
        end
        endcase
    end
    
    always @* begin
        case(dir)
            1'b0: begin
                if(out>n) next_out = out - n; 
                else next_out = out + n;
            end
            1'b1: begin
                next_out = out - 2**n;
            end
        endcase
    end
    
endmodule
