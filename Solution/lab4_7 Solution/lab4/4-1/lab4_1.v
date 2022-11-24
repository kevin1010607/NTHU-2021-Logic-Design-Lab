`timescale 1ns / 1ps

module debounce(output reg pulse, input bt,input clk);
    reg [3:0]shift_reg;
    wire debounced;
    always@(posedge clk)begin
        shift_reg[3:1]<=shift_reg[2:0];
        shift_reg[0]<=bt;
    end
    assign debounced=((shift_reg==4'b1111)?1'b1:1'b0);
    
     reg delay;
    always@(posedge clk)begin
        if(debounced==1'b1& delay==0)
            pulse=1;
        else
            pulse=0;
        delay=debounced;
    end
endmodule

module debounce_only(output debounced, input bt,input clk);
    reg [3:0]shift_reg;
    always@(posedge clk)begin
        shift_reg[3:1]<=shift_reg[2:0];
        shift_reg[0]<=bt;
    end
    assign debounced=((shift_reg==4'b1111)?1'b1:1'b0);
endmodule
module lab4_1(input clk, input rst, input en, input dir, input speedup, input speeddown , output reg [3:0] DIGIT, output reg[6:0]DISPLAY,output reg max, output reg min);
reg [10:0]number;
reg [25:0]oneseccounter=0;
reg [2:0]levelcounter=0;
wire count;
reg [4:0]BCD0;
reg [4:0]value;
reg realdir;
reg next_dir;
reg [19:0]refresh_counter;
wire change_dir;
reg realen;
reg next_en;
wire change_en;
wire realrst;
wire [1:0]ledact;
wire real_up;
wire real_down;
reg [2:0]speed;
reg [2:0]next_speed;
debounce_only dedir( .debounced(change_dir), .bt(dir), .clk(clk));
debounce deen( .pulse(change_en), .bt(en), .clk(clk));
debounce derst( .pulse(realrst), .bt(rst), .clk(clk));
debounce despeedup( .pulse(real_up), .bt(speedup), .clk(clk));
debounce despeeddown( .pulse(real_down), .bt(speeddown), .clk(clk));
always@(posedge clk or posedge realrst)begin
    if(realrst==1)begin
        refresh_counter<=0;
    end
    else
        refresh_counter<=refresh_counter+1;
end
assign ledact=refresh_counter[19:18];

always@(posedge clk or posedge realrst)begin
    if(realrst==1)begin
        realdir<=1;
        realen<=0;
        speed <= 0;
    end
    else begin
        realdir<=next_dir;
        realen<=next_en;
        speed <= next_speed;
    end
end
always@(*)begin
    if(real_up)begin
        if(speed<3)
            next_speed = speed +1;
        else
            next_speed = speed;
    end
    else begin
        if(real_down)begin
            if(speed > 0)
                next_speed = speed -1;
            else
                next_speed = speed;
        end
        else
            next_speed = speed;
    end
end
always@(*)begin
    if(dir)
        next_dir=0;
    else
        next_dir=1;
end
always@(*)begin
    if(change_en)
        next_en=~realen;
    else
        next_en=realen;
end
always@(posedge clk or posedge realrst)begin
    if(realrst==1)begin
         oneseccounter<=0;
    end
    else begin
        oneseccounter<=oneseccounter+1;
    end
end

always@(posedge count or posedge realrst)begin
    if(realrst==1)begin
         levelcounter <= 0;
    end
    else begin
         levelcounter <= levelcounter+1;
    end
end

assign count=oneseccounter[23];
reg trueclk;
always@(posedge clk or posedge realrst)begin
    if(realrst==1)begin
        trueclk <= 0;
    end
    else begin
        trueclk <= oneseccounter[25-speed];
    end
end
always@(posedge trueclk or posedge realrst)begin
    if(realrst==1)begin
        number<=0;
        max<=0;
        min<=0;
    end
    else if(realen==1)begin
        if(realdir==1)begin
            if(number!=99)begin
                number<=number+1;
                max<=0;
                min<=0;
            end
            else
                max<=1;
        end
        else begin
            if(number!=0)begin
                min<=0;
                max<=0;
                number<=number-1;
            end
            else
                min=1;
         end
    end
end
always@(*)begin
    case(ledact)
        2'b00:begin
            DIGIT=4'b0111;
            value= speed;
        end
        2'b01:begin
            DIGIT=4'b1011;
            value=(realdir==1?10:11);
        end
        2'b10:begin
            DIGIT=4'b1101;
            value=number/10;
        end
        2'b11:begin
            DIGIT=4'b1110;
            value=number%10;
        end
    endcase
end

always@(*)begin
    case(value)
        4'd0:DISPLAY=7'b1000000;
        4'd1:DISPLAY=7'b1111001;
        4'd2:DISPLAY=7'b0100100;
        4'd3:DISPLAY=7'b0110000;
        4'd4:DISPLAY=7'b0011001;
        4'd5:DISPLAY=7'b0010010;
        4'd6:DISPLAY=7'b0000010;
        4'd7:DISPLAY=7'b1111000;
        4'd8:DISPLAY=7'b0000000;
        4'd9:DISPLAY=7'b0010000;
        4'd10:DISPLAY=7'b1011100;
        4'd11:DISPLAY=7'b1100011;
        default:DISPLAY=7'b1111111;
    endcase
end


endmodule
