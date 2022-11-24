module one_pulse (
    input clk,
    input pb_in,
    output reg pb_out
);

  reg pb_in_delay;

  always @(posedge clk) begin
    if (pb_in == 1'b1 && pb_in_delay == 1'b0) begin
      pb_out <= 1'b1;
    end else begin
      pb_out <= 1'b0;
    end

    pb_in_delay <= pb_in;
  end
endmodule
