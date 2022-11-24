`timescale 1ns/100ps
module lab3_3_t;
    reg clk, rst, en, speed;
    wire [15:0] led;
    reg pass;
    reg [15:0] Led;
    parameter half_cycle = 5;

    lab3_3 m(clk, rst, en, speed, led);

    always #5 clk = ~clk;
    always @(posedge clk, posedge rst) begin
        cal();
    end
    always @(negedge clk) begin
        test();
    end

    initial begin
        clk = 1'b1;
        rst = 1'b0;
        en = 1'b1;
        speed = 1'b0;
        pass = 1'b1;

        $display("Starting the simulation...");

        // Test the reset function
        #(half_cycle) rst = 1'b1;
        #(half_cycle*5) if(!pass) $display(">>>> Error1 occurs.");
        
        #(half_cycle*100) rst = 1'b0;
        #5000 speed = 1'b1;
        #5000

        $display("%g Terminating the simulation...", $time);

        if(pass) $display(">>>> [PASS]  Congratulation!");
        else $display(">>>> [ERROR]  Try it again!");

        $finish;
    end

    task test;
        begin
            if(led != Led) begin
                error();
            end
        end
    endtask

    task cal;
        begin
            
        end
    endtask

    task error;
        begin
            pass = 1'b0;
        end
    endtask
endmodule