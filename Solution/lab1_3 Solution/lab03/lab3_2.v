module lab3_2(clk,rst,en,dir,led);
    input clk;
    input rst;
    input en;
    input dir;
    output reg [15:0]led;

    wire clk_div;
    reg [3:0] count;
    reg [3:0] next_count;
    reg [1:0] state,next_state;
    reg [15:0] next_led;
    reg dir_flag;
    reg mem_flag;
    clock_divider #(25)div1(.clk(clk),.clk_div(clk_div));
    

    parameter RESET=2'b00;
    parameter FLASH=2'b01;
    parameter SHIFT=2'b10;
    parameter SPREAD=2'b11;

    always @(posedge clk_div or posedge rst) begin
        if(rst==1'b1)
            state<=RESET;
        else
            state<=next_state;
    end


    always @(posedge clk_div or posedge rst) begin
        if(rst==1'b1)
            count<=0;
        else
            count<=next_count;
    end
    
    always @* begin
        if(state==FLASH) begin
            if(en==1)
                next_count=count+1'b1;  
            else
                next_count=count;
        end
        else begin
            next_count=0;
        end
    end

    always@(posedge clk_div or posedge rst)begin
        if(rst)
            led <= 16'b1111111111111111;
        else
            led <= next_led;
    end
    
    always@(posedge clk or posedge rst)begin
        if(rst)
            mem_flag<=1'b0;
        else
            mem_flag<=dir_flag;
    end

    always @(*) begin
        if(led==16'b1010101010101010)
            dir_flag=dir;
        else
            dir_flag=mem_flag;
    end


    always @(*) begin
        if(en==1'b0)      
            next_led = led;
        else if(next_state==RESET)
            next_led = 16'b1111111111111111;
        else if(next_state==FLASH)
            if(state!=FLASH)
                next_led[15:0]=0;
            else
                next_led=~led;
        else if(next_state==SHIFT)
            if(state!=SHIFT)
                next_led[15:0]=16'b1010101010101010;
            else if(dir==1'b0) begin
                if(dir_flag==1'b1 && led[15]==1'b0) begin
                    next_led=led>>1;
                    next_led[15]=1'b1;
                end
                else
                    next_led=led>>1;
            end
            else begin
                if(dir_flag==1'b0 && led[0]==1'b0) begin
                    next_led=led<<1;
                    next_led[0]=1'b1;
                end
                else
                    next_led=led<<1;
            end
        else
            if(state!=SPREAD)
                next_led[15:0]=16'b0000000110000000;
            else if(dir==1'b0) begin
                next_led[15:8]={led[14:8],1'b1};
                next_led[7:0]={1'b1,led[7:1]};
            end
            else begin
                next_led[15:8]={1'b0,led[15:9]};
                next_led[7:0]={led[6:0],1'b0};
            end
    end

    always @* begin
        next_state=RESET;
        case(state)
        RESET: begin
            if(rst==1'b0 && en==1'b1)
                next_state=FLASH;
            else
                next_state=RESET;
        end
        FLASH: begin
            if(count>4'd11 || count==4'd11)
                next_state=SHIFT;
            else
                next_state=FLASH;
        end
        SHIFT: begin
            if(led[15:0]==0)
                next_state=SPREAD;
            else
                next_state=SHIFT;
        end
        SPREAD: begin
            if(led[15:0]==16'b1111111111111111 && en==1'b1)
                next_state=FLASH;
            else
                next_state=SPREAD;
        end
        endcase
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