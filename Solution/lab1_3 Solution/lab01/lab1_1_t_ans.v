`timescale 1ns/100ps

module lab1_1_t;

  reg [3:0] a;
  reg [1:0] b;
  wire [3:0] d;
  reg dir;
  reg pass;
  reg clk;

  // TODO 1: Please instantiate lab1_1 with correct interconnection
  // where a, b and dir are inputs; d is output.

  lab1_1 shifter(
    .d(d),
    .a(a),
    .b(b),
    .dir(dir)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b1;
    {a, b, dir} = 7'd0;  // initailize the counter
    pass = 1'b1;  // use the pass flag to check whether you pass the simulation

    $display("Starting the simulation");

    // In this block, the testbench will exhaustively try all possible
    // combinations of a, b and dir to test the correctness of the
    // circuit with the task function "test".
    repeat (2 ** 7) begin
      @ (posedge clk)
        test;

      @ (negedge clk)
        // TODO 2: Increase the counter {a, b, dir} by 1 at negative clock edges.
        {a, b, dir} = {a, b, dir} + 1;
    end

    $display("%g Terminating simulation...", $time);
    if (pass) $display(">>>> [PASS]  Congratulations!");
    else      $display(">>>> [ERROR] Try it again!");
    $finish;
  end
            
  task test; 
    begin
      if (dir) begin
        if (b == 2'b00) begin
          if (d !== a) 
            printerror;
        end else if (b == 2'b01) begin
          if (d !== {1'b0, a[3:1]})
            printerror;
        end else if (b == 2'b10) begin
          if (d !== {2'b00, a[3:2]})
            printerror;
        end else begin
          if (d !== {3'b000, a[3]}) 
            printerror;
        end
      end else begin
        if (b == 2'b00) begin
          if (d !== a) 
            printerror;
        end else if (b == 2'b01) begin
          // TODO 3: Complete the condition so that a << 1 can be tested correctly.
          if (d !== {a[2:0], 1'b0})
            printerror;
        end else if (b == 2'b10) begin
          if (d !== {a[1:0], 2'b00})
            printerror;
        end else begin
          if (d !== {a[0], 3'b000}) 
            printerror;
        end
      end
    end
  endtask

  task printerror;
    begin
    // TODO 4: Set the value of signal "pass" to 0 when the result is not correct.
    pass = 1'b0;
    $display($time," Error:  a = %b, b = %b, d = %b, dir = %b",
      a, b, d, dir);
    end
  endtask
endmodule
