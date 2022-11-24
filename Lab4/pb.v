module debounce(
    output wire pb_debounced,
    input pb,
    input clk); 
    reg [3:0] shift, next_shift;
    // shift
    always @(posedge clk) begin
        shift <= next_shift;
    end
    // next_shift
    always @* begin
        next_shift = {shift[2:0], pb};
    end
    // pb_debounced
    assign pb_debounced = &shift;
endmodule

module onepulse(
    input pb_debounced,
    input clk,
    output wire pb_1pulse); 
    reg pb_debounced_delay;
    // pb_debounced_delay
    always @(posedge clk) begin
        pb_debounced_delay <= pb_debounced;
    end
    // pb_1pulse
    assign pb_1pulse = pb_debounced&(~pb_debounced_delay);
endmodule