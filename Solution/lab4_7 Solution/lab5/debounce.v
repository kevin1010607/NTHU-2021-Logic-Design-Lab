module debounce #(
    parameter n = 8
) (
    input  clk,
    input  pb_in,
    output pb_out
);

  reg [n-1:0] shift_reg;

  assign pb_out = (shift_reg == {n{1'b1}});

  always @(posedge clk) begin
    shift_reg <= {shift_reg[n-2:0], pb_in};
  end
endmodule
