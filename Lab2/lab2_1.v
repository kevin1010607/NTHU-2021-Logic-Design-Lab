`timescale 1ns/100ps
module lab2_1(
    input clk,
    input rst,
    output reg [5:0] out);
    parameter INC = 1'b0;
    parameter DEC = 1'b1;
    reg state, state_next, state_now;
    reg [5:0] cnt, cnt_next, cnt_now;
    reg [5:0] out_next;
    wire out_equal_0, out_equal_63;

    // FF update
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= INC;
            cnt <= 0;
            out <= 0;
        end
        else begin
            state <= state_next;
            cnt <= cnt_next;
            out <= out_next;
        end
    end
    // out_equal_0
    assign out_equal_0 = (out==6'd0)?1:0;
    // out_equal_63
    assign out_equal_63 = (out==6'd63)?1:0;
    // state_now
    always @* begin
        state_now = state;
        if(out_equal_0) state_now = INC;
        else if(out_equal_63) state_now = DEC;
    end
    // cnt_now
    always @* begin
        cnt_now = cnt;
        if(out_equal_0 || out_equal_63) cnt_now = 6'd0;
    end
    // state_next
    always @* begin
        state_next = state_now;
        if(out_equal_0) state_next = INC;
        else if(out_equal_63) state_next = DEC;
    end
    // cnt_next
    always @* begin
        cnt_next = cnt_now+1'b1;
        if(out_equal_0 || out_equal_63) cnt_next = 6'd1;
    end
    // out_next
    always @* begin
        case(state_now)
            INC: begin
               if(out > (cnt_now+1'b1)) out_next = out-(cnt_now+1'b1); 
               else out_next = out+(cnt_now+1'b1);
            end
            DEC: begin
                out_next = out-(6'd1<<cnt_now);
            end
        endcase
    end
endmodule