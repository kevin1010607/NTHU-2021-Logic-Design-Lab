`timescale 1ns/100ps
module lab3_2_t;
    reg clk, rst, en, dir;
    wire [15:0] led;
    reg pass;
    reg [2:0] state, cnt;
    reg [15:0] Led;
    reg [47:0] store;
    parameter FLASH = 3'b001;
    parameter SHIFT = 3'b010;
    parameter EXPAND = 3'b100;
    parameter half_cycle = 5;

    lab3_2 m(clk, rst, en, dir, led);

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
        dir = 1'b1;
        pass = 1'b1;

        $display("Starting the simulation...");

        // Test the reset function
        #(half_cycle) rst = 1'b1;
        #(half_cycle*5) if(!pass) $display(">>>> Error1 occurs.");

        // Test the enable function
        #(half_cycle) rst = 1'b0;
        #(half_cycle*10) en = 1'b0;
        #(half_cycle*10) if(!pass) $display(">>>> Error2 occurs.");

        // Test FLASH -> SHIFT
        #(half_cycle) en = 1'b1;
        #(half_cycle*20) if(!pass) $display(">>>> Error3 occurs.");

        // Test different dir at SHIFT mode
        #(half_cycle*10) dir = 1'b0;
        #(half_cycle*30) if(!pass) $display(">>>> Error4 occurs.");

        // Test SHIFT -> EXPAND
        #(half_cycle*20) if(!pass) $display(">>>> Error5 occurs.");

        // Test different dir at EXPAND mode
        #(half_cycle*4) dir = 1'b1;
        #(half_cycle*10) if(!pass) $display(">>>> Error6 occurs.");

        // Test EXPAND -> FLASH
        #(half_cycle*2) dir = 1'b0;
        #(half_cycle*20) if(!pass) $display(">>>> Error7 occurs.");

        #(half_cycle*10)

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
                state = FLASH;
                cnt = 3'd0;
                store = 48'd0;
            end else if(en == 1'b1) begin
                case(state)
                    FLASH: begin
                        if(cnt == 3'd6) begin
                            Led = {8{2'b10}};
                            state = SHIFT;
                            cnt = 3'd0;
                            store = {16'd0, {8{2'b10}}, 16'd0};
                        end else begin
                            if(Led == 16'd0) cnt = cnt+1'b1;
                            Led = Led^{16{1'b1}};
                        end
                    end
                    SHIFT: begin
                        if(Led == 16'd0) begin
                            Led = 16'b0000_0001_1000_0000;
                            state = EXPAND;
                        end else begin
                            store = dir?store<<1:store>>1;
                            Led = store[31:16];
                        end
                    end
                    EXPAND: begin
                        if(Led == {16{1'b1}}) begin
                            Led = 16'd0;
                            state = FLASH;
                        end else begin
                            if(dir == 1'b0) Led = {Led[14:8], 2'b11, Led[7:1]};
                            else Led = {1'b0, Led[15:9], Led[6:0], 1'b0};
                        end
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