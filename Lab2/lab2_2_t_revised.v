`timescale 1ns / 100ps
module lab2_2_t;
    reg	clk, rst, carA, carB;
    wire [2:0] lightA, lightB;
    reg pass;
    reg sec2_a, sec2_b;
    reg [2:0] lighta, lightb;
    
    lab2_2 counter (clk, rst, carA, carB, lightA, lightB);
  
    always #5 clk = ~clk;
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
    {carA, carB} = 2'b00;
    {lighta, lightb} = 6'b001100;
  

    $display("Starting the simulation");
    
    //Test the reset function
    #5 rst = 1'b1;
       {carA, carB} = 2'b01; 
    #25 if(!pass)  $display(">>>> Error1 occurs.");
       
    // Test the boundary conditions should keep the lightA unchanged
    #5 rst = 1'b0;
       {carA, carB} = 2'b01;
    #10 {carA, carB} = 2'b11;
    repeat (3) begin
        #10 {carA, carB} = {carA, carB} << 1;
    end
    if(!pass)  $display(">>>> Error2 occurs.");
    
    // Test the boundary conditions should change the lightA
    rst = 1'b1;
    {lighta, lightb} = 6'b001100;
    #10 rst = 1'b0;
        {carA, carB} = 2'b01;
    #25 if(!pass)  $display(">>>> Error3 occurs.");
    
    // Test the boundary conditions should keep the lightB unchanged
    #5 {carA, carB} = 2'b10;
    #10 {carA, carB} = 2'b11;
    repeat (3) begin
       #10 {carA, carB} = {carA, carB} >> 1;
    end
    if(!pass)  $display(">>>> Error4 occurs.");
    
    // Test the boundary conditions should change the lightB
    {carA, carB} = 2'b10;
    #35 if(!pass)  $display(">>>> Error5 occurs.");

    $display("%g Terminating the simulation...", $time);

    if(pass)  $display(">>>> [PASS]  Congratulations!");
    else      $display(">>>> [ERROR] Try it again!");

    $finish;
  end
            
  task test; 
    begin
        if ({lightA, lightB} != {lighta, lightb}) error();
    end
  endtask
  
  task cal; 
    begin
    if(rst==1'b1) begin
        {sec2_a, sec2_b} = 2'b00;
        {lighta, lightb} = 6'b001100;
    end else begin
      case({lighta, lightb})
        6'b001100: begin
          if(carB&&!carA&&sec2_a) {lighta, lightb} = 6'b010100;
          if(!sec2_a) sec2_a = sec2_a + 2'b1;
        end
        6'b010100: begin
          {lighta, lightb} = 6'b100001;
          sec2_a = 2'b00;
        end
        6'b100001: begin
          if (carA&&!carB&&sec2_b) {lighta, lightb} = 6'b100010;
          if(!sec2_b) sec2_b = sec2_b + 2'b1;
        end
        6'b100010: begin
          {lighta, lightb} = 6'b001100;
          sec2_b = 2'b00;
        end
        default: begin
          {lighta, lightb} = 6'b111111;
          {sec2_a, sec2_b} = 2'b00;
        end
      endcase
      end  
    end
  endtask

  task error;
    begin
      pass = 0;
    end
  endtask
    
endmodule
