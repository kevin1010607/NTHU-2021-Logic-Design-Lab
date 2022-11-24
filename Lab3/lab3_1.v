module lab3_1(
    input clk,
    input rst,
    input en,
    input speed,
    output reg [15:0] led);
    wire clk1, clk0, clk_now;
    reg [15:0] next_led;
    // clk1, clk0
    clock_divider #(.n(27)) speed1(.clk(clk), .clk_div(clk1));
    clock_divider #(.n(24)) speed0(.clk(clk), .clk_div(clk0));
    // clk_now
    assign clk_now = speed?clk1:clk0;
    // led
    always @(posedge clk_now, posedge rst) begin
        if(rst == 1'b1) led <= {16{1'b1}};
        else led <= next_led;
    end
    // next_led
    always @* begin
        next_led = led;
        if(en == 1'b1) next_led = led^{16{1'b1}};
    end
endmodule

module clock_divider #(parameter n=25)(
    input clk,
    output wire clk_div);
    reg [n-1:0] cnt = 0, next_cnt;
    // cnt
    always @(posedge clk) begin
        cnt <= next_cnt;
    end
    // next_cnt
    always @* begin
        next_cnt = cnt+1'b1;
    end
    // clk_div
    assign clk_div = cnt[n-1];
endmodule
