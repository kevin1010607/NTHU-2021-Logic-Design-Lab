`timescale 1ns/100ps
module lab3_1_t;
    reg clk, rst, en, speed;
    wire [15:0] led;
    reg pass;
    wire clk1, clk0, clk_now;
    reg [15:0] Led;
    parameter half_cycle = 5;

    // clk1 = 3, clk0 = 1
    clock_divider #(3) speed1(clk, clk1);
    clock_divider #(1) speed0(clk, clk0);
    lab3_1 m(clk, rst, en, speed, led);
    
    assign clk_now = speed?clk1:clk0;
    always #5 clk = ~clk;
    always @(posedge clk_now, posedge rst) begin
        cal();
    end
    always @(negedge clk_now) begin
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

        // Test the enable function
        #(half_cycle) rst = 1'b0;
        #(half_cycle*10) en = 1'b0;
        #(half_cycle*10) if(!pass) $display(">>>> Error2 occurs.");

        // Test speed = 0
        #(half_cycle) en = 1'b1;
        #(half_cycle*12) if(!pass) $display(">>>> Error3 occurs.");

        // Test speed = 1
        #(half_cycle) speed = 1'b1;
        #(half_cycle*48) if(!pass) $display(">>>> Error4 occurs.");

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
            if(rst == 1'b1) begin
                Led = {16{1'b1}};
            end else if(en == 1'b1) begin
                Led = Led^{16{1'b1}};
            end
        end
    endtask

    task error;
        begin
            pass = 1'b0;
        end
    endtask
endmodule