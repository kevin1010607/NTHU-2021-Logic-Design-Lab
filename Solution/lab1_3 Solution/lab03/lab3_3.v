module lab3_3 (
    input clk,
    input rst,
    input en,
    input speed,
    output [15:0] led
    );

    wire clk_1,clk_3,clk_div23,clk_div25,clk_div24,clk_div26;
    reg [15:0] led_1,led_3;
    reg [15:0] next_led_1,next_led_3;
   
    reg[3:0] position_1,position_3;
    reg[3:0] next_position_1,next_position_3;
    
    reg dir;
    reg next_dir;
    
	clock_divider #(26) div1(.clk(clk), .clk_div(clk_div26));
    clock_divider #(24) div2(.clk(clk), .clk_div(clk_div24));
    clock_divider #(25) div3(.clk(clk), .clk_div(clk_div25));
    clock_divider #(23) div4(.clk(clk), .clk_div(clk_div23));

    assign led = led_1 | led_3;
    assign clk_1=(speed)?clk_div24 : clk_div23;
    assign clk_3=(speed)?clk_div26 : clk_div25;
    
    always@(posedge clk_3 or posedge rst)begin
        if(rst) begin
            led_3<=16'b0000000000000111;
            position_3<=4'd1;
        end else begin
            led_3<=next_led_3;
            position_3<=next_position_3;
        end
    end
    
    always@(posedge clk_1 or posedge rst)begin
        if(rst) begin
            led_1<=16'b1000000000000000;
            position_1<=4'd15;
            dir<=0;
        end else begin
            led_1<=next_led_1;
            position_1<=next_position_1;
            dir<=next_dir;
        end
    end

    always @(*) begin
        if(en==1'b1) begin
            next_led_3[15:1]=led_3[14:0];
            next_led_3[0]=led_3[15];
        end
        else begin
            next_led_3=led_3;
        end
    end
    
    always @(*) begin
        if(en==1'b1) begin
            if(position_3==4'd15)
                next_position_3=4'd0;
            else
                next_position_3=position_3+1'd1;
        end
        else
            next_position_3=position_3;
    end

    always @(*) begin
        if(en==1'b1) begin
            //left to right
            if(dir==1'b0) begin
                if(position_1>=position_3) begin
                    if(position_1-position_3<=2) begin
                        next_dir=1'b1;
                        next_position_1=position_1+4'd1;
                        next_led_1[0] = led_1[15];
                        next_led_1[15:1] = led_1[14:0];
                    end
                    else begin
                        next_dir=1'b0;
                        next_position_1=position_1-4'd1;
                        next_led_1[15] = led_1[0];
                        next_led_1[14:0] = led_1[15:1];
                    end
                end
                else if(position_1==4'd1 && position_3==4'd15) begin
                    next_dir=1'b1;
                    next_position_1=position_1+4'd1;
                    next_led_1[0] = led_1[15];
                    next_led_1[15:1] = led_1[14:0];
                end
                else if(position_1==4'd0) begin
                    if(position_3==4'd15 || position_3==4'd14) begin
                        next_dir=1'b1;
                        next_position_1=position_1+4'd1;
                        next_led_1[0] = led_1[15];
                        next_led_1[15:1] = led_1[14:0];
                    end
                    else begin
                        next_dir=1'b0;
                        next_position_1=4'd15;
                        next_led_1[15] = led_1[0];
                        next_led_1[14:0] = led_1[15:1];
                    end
                end
                else begin
                    next_dir=1'b0;
                    next_position_1=position_1-4'd1;
                    next_led_1[15] = led_1[0];
                    next_led_1[14:0] = led_1[15:1];
                end
            end
            else begin //right to left
                if(position_3>=position_1) begin
                    if(position_3-position_1<=2) begin
                        next_dir=1'b0;
                        next_position_1=position_1-4'd1;
                        next_led_1[15] = led_1[0];
                        next_led_1[14:0] = led_1[15:1];
                    end
                    else begin
                        next_dir=1'b1;
                        next_position_1=position_1+4'd1;
                        next_led_1[0] = led_1[15];
                        next_led_1[15:1] = led_1[14:0];
                    end
                end
                else if(position_1==4'd14 && position_3==4'd0) begin
                    next_dir=1'b0;
                    next_position_1=position_1-4'd1;
                    next_led_1[15] = led_1[0];
                    next_led_1[14:0] = led_1[15:1];
                end
                else if(position_1==4'd15) begin
                    if(position_3==4'd0 || position_3==4'd1) begin
                        next_dir=1'b0;
                        next_position_1=position_1-4'd1;
                        next_led_1[15] = led_1[0];
                        next_led_1[14:0] = led_1[15:1];
                    end
                    else begin
                        next_dir=1'b1;
                        next_position_1=4'd0;
                        next_led_1[0] = led_1[15];
                        next_led_1[15:1] = led_1[14:0];
                    end
                end
                else begin
                    next_dir=1'b1;
                    next_position_1=position_1+4'd1;
                    next_led_1[0] = led_1[15];
                    next_led_1[15:1] = led_1[14:0];
                end
            end
        end
        else begin
            next_dir=dir;
            next_position_1=position_1;
            next_led_1=led_1;
        end
    end

	

endmodule


module clock_divider #(parameter n=25) (clk,clk_div);
    
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

