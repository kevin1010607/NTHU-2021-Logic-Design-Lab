`timescale 1ns/100ps
module lab2_1_t;
    reg clk, rst;
    wire [5:0] out;
    reg pass, state;
    reg [5:0] cnt, out_;
    parameter half_cycle = 20;

    lab2_1 counter(clk, rst, out);

    always #(half_cycle) clk = ~clk;
    always @(posedge clk, posedge rst) begin
        cal();
    end
    always @(negedge clk) begin
        test();
    end

    initial begin
        clk = 1'b1;
        pass = 1'b1;
        rst = 1'b0;
        out_ = 6'd0;

        $display("Starting the simulation");

        // Test the reset function at begining
        #(half_cycle) rst = 1'b1;
        #(half_cycle*5) if(!pass) $display(">>>> Error1 occurs.");

        // Test the increasing and decreasing series
        #(half_cycle) rst = 1'b0;
        #(half_cycle*130) if(!pass) $display(">>>> Error2 occurs.");

        // Test the reset function at increasing series
        #(half_cycle*3/2) rst = 1'b1;
        #(half_cycle/2)
        #(half_cycle*5) if(!pass) $display(">>>> Error3 occurs.");

        #(half_cycle) rst = 1'b0;
        #(half_cycle*120)

        // Test the reset function at decreasing series
        #(half_cycle*3/2) rst = 1'b1;
        #(half_cycle/2)
        #(half_cycle*5) if(!pass) $display(">>>> Error4 occurs.");

        #(half_cycle*5)

        $display("%g Terminating the simulation...", $time);

        if(pass) $display(">>>> [PASS]  Congratulations!");
        else $display(">>>> [ERROR] Try it again!");

        $finish;
    end

    task test;
        begin
            if(out != out_) begin
                error();
                $display("out = %d, out_ = %d.", out, out_);
            end
        end
    endtask

    task cal;
        begin
            if(rst == 1'b1) begin
                state = 1'b0;
                cnt = 6'd0;
                out_ = 6'd0;
            end else begin
                case(state)
                    1'b0: begin
                        if(out_ > (cnt+1'b1)) out_ = out_-(cnt+1'b1);
                        else out_ = out_+(cnt+1'b1);
                        if(out_ == 6'd63) begin
                            state = 1'b1;
                            cnt = 6'd0;
                        end
                        else cnt = cnt+1'b1;
                    end
                    1'b1: begin
                        out_ = out_-(6'd1<<cnt);
                        if(out_ == 6'd0) begin
                            state = 1'b0;
                            cnt = 6'd0;
                        end
                        else cnt = cnt+1'b1;
                    end
                endcase
            end 
        end
    endtask

    task error;
        begin
            pass = 1'b0;
        end
    endtask
endmodule