`timescale 1ns/100ps

module lab1_2_t;

  reg  [3:0] a;
  reg  [1:0] b;
  reg  [1:0] aluctr;
  wire [3:0] d;
  reg  pass;
  reg clk;
    
  lab1_2 ALU(
    .a(a),
    .b(b),
    .aluctr(aluctr),
    .d(d));

  always #5 clk = ~clk;
   
  initial begin
    clk = 1'b1;
    {a, b, aluctr} = 8'd0;
    pass = 1'b1;  

    $display("Starting the simulation");

    repeat (2 ** 8) begin
      @ (posedge clk)
        test;
        
      @ (negedge clk)
        {a, b, aluctr} = {a, b, aluctr} + 1;
        
    end

    $display("%g Terminating simulation...", $time);
    if (pass) $display(">>>> [PASS]  Congratulations!");
    else      $display(">>>> [ERROR] Try it again!");
    $finish;
  end

  task test;
    begin
      if (aluctr == 2'b00) begin
        if (d !== a << b)
          printerror;
      end else if (aluctr == 2'b01) begin
        if (d !== a >> b)
          printerror;
      end else if (aluctr == 2'b10) begin
        if (d !== a + b)
          printerror;
      end else begin
        if (d !== a - b)
          printerror;
      end
    end
  endtask
    
  task printerror;
    begin
      pass = 1'b0;
      $display($time, " Error:  aluctr = %b, a = %b, b = %b, d = %b", aluctr, a, b, d);
    end
  endtask
    
endmodule
