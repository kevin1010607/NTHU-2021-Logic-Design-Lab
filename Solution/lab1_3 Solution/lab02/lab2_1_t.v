// Change the runtime to 10000ns before simulation
`timescale 1ns / 100ps
module lab2_1_t;
    reg clk,rst;
    wire [5:0] out;
    reg pass = 1;
    reg [5:0] num_temp, num_out, n;
    reg dir;
    

    lab2_1 counter(clk,rst,out);
    
    always  #5  clk = ~clk;
    
    initial begin
    clk = 1'b1;
    rst = 1'b1;   
    pass = 1'b1;
    num_temp = 6'd0;
    num_out = 6'd0;
    dir = 0;
    n = 6'd1;
    
    
    #10
    rst = 1'b0;  
   
    $display("Starting the simulation");

    repeat (64*2) begin
      
      @ (posedge clk)
        test();
        cal();
    end

    $display("%g Terminating the simulation...", $time);

    if(pass)  $display(">>>> [PASS]  Congratulations!");
    else      $display(">>>> [ERROR] Try it again!");

    $finish;
  end
            
  task test; 
    begin
        if (out != num_out ) error();
    end
  endtask

  task cal; 
    begin
        num_temp = num_out;
        if (dir==1'b0) begin
            num_out = (num_temp>n)? num_temp-n: num_temp+n;
            if(num_out==6'd63) begin
                dir = 1'b1;
                n = 6'b0;
            end else begin
                n = n+6'd1;
            end
        end else begin
            num_out = num_temp-2**n;
            if(num_out==6'd0) begin
                dir = 1'b0;
                n = 6'b1;
            end else begin
                n = n+6'd1;
            end
        end
       
        
    end
  endtask

  task error;
    begin
      pass = 0;
    end
  endtask

endmodule
