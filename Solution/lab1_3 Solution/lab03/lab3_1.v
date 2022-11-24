module lab3_1(clk,rst,en,speed,led);
    input clk;
    input rst;
    input en;
    input speed;
    output reg [15:0]led;

    wire clk_led,clk_div24,clk_div27;
    reg [15:0] next_led;
    clock_divider #(27) div1(.clk(clk), .clk_div(clk_div27));
    clock_divider #(24) div2(.clk(clk), .clk_div(clk_div24));

    assign clk_led= (speed)?clk_div27 : clk_div24;

    always @(posedge clk_led or posedge rst) begin
        if(rst==1'b1) begin
            led[15:0]<=16'b1111111111111111;
        end
        else begin
            led<=next_led;
        end
    end
    
    always @* begin
        if(en==1'b0) begin
            next_led=led;
        end
        else begin
            next_led=~led;
        end
    end

endmodule

module clock_divider #(parameter n=27) (clk,clk_div);
    
    input clk;
    output clk_div;

    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        num<=next_num;
    end

    assign next_num=num+1;
    assign clk_div=num[n-1];
endmodule