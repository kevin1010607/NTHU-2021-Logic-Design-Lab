module clock_divider_2_square #(
    parameter n = 25
) (
    input  clk,
    output clk_div
);
  reg  [n-1:0] num = 0;
  wire [n-1:0] next_num;

  assign clk_div  = num[n-1];
  assign next_num = num + 1;

  always @(posedge clk) begin
    num <= next_num;
  end
endmodule
