`timescale 1ns/100ps
module lab4_2_t;
    reg clk, rst, en, input_number, enter, count_down;
    wire [3:0] DIGIT;
    wire [6:0] DISPLAY;
    wire led0;
    reg pass;

    lab4_2 m(clk, rst, en, input_number, enter, count_down, DIGIT, DISPLAY, led0);

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
        en = 1'b0;
        input_number = 1'b0;
        enter = 1'b0;
        count_down = 1'b0;
        pass = 1'b1;

        $display("Starting the simulation...");

        #5 rst = 1'b1;
        #25 rst = 1'b0;
        #10 en = 1'b1;
        #1 en = 1'b0;
        #2 en = 1'b1;
        #5 en = 1'b0;
        #10 en = 1'b1;
        #100 en = 1'b0;
        #50


        $display("%g Terminating the simulation...", $time);

        if(pass) $display(">>>> [PASS]  Congratulation!");
        else $display(">>>> [ERROR]  Try it again!");

        $finish;
    end

    task test;
        begin

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