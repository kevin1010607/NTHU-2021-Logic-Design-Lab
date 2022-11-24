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

module lab4_2(input clk, input rst, input en,input enter,input input_number,input count_down,output reg[3:0]DIGIT, output reg[6:0]DISPLAY, output led0);
reg [10:0]number,show_number;
reg [26:0]oneseccounter;
reg [4:0]value;
reg [19:0]refresh_counter;
wire realrst,count,enter_down,input_number_down,counting_down;
wire [1:0]ledact;
reg [2:0]setnumber,next_setnumber;
reg dir,next_dir;
reg [1:0]state,next_state;
reg [3:0]minute,tensec,sec,msec,next_minute,next_tensec,next_sec,next_msec;
reg [3:0]cmin,ctensec,csec,cmsec,next_cmin,next_ctensec,next_csec,next_cmsec;
parameter DIRECT = 2'b00;
parameter SETTING = 2'b01;
parameter COUNT = 2'b10;
//decounce & onepulse
debounce decountdown( .pulse(counting_down), .bt(count_down), .clk(clk));
debounce enterdown( .pulse(enter_down), .bt(enter), .clk(clk));
debounce inputnum( .pulse(input_number_down), .bt(input_number), .clk(clk));
//debounce derst( .pulse(realrst), .bt(rst), .clk(clk));

always@(*)begin//state transition
    case(state)
        DIRECT:begin
            if(enter_down)next_state = state + 1;
            else next_state = state;
            next_setnumber = 0;
        end
        SETTING:begin
            if(enter_down)next_setnumber = setnumber + 1;
            else next_setnumber = setnumber;
            if(setnumber == 4)next_state = state + 1;
            else next_state = state;
        end
        default:begin
            next_state = state;
            next_setnumber = setnumber;
        end
    endcase
end



always@(posedge clk , posedge rst)begin
    if(rst)begin
        state <= 0;
        setnumber <= 0;
        dir <= 1;
        sec <= 0;
        tensec <= 0;
        msec <= 0;
        minute <= 0;
    end
    else begin
        state <= next_state;
        setnumber <= next_setnumber;
        dir <= next_dir;
        sec <= next_sec;
        tensec <= next_tensec;
        msec <= next_msec;
        minute <= next_minute;
    end
end

always@(posedge clk or posedge rst)begin
    if(rst)refresh_counter <= 0;
    else refresh_counter <= refresh_counter+1;
end
always@(posedge clk or posedge rst)begin
    if(rst)begin
        cmin <= 0;
        csec <= 0;
        ctensec <= 0;
        cmsec <= 0;
    end
    else begin
        if(state == 1 && dir == 0 )begin
            cmin <=  minute;
            csec <= sec;
            ctensec <= tensec;
            cmsec <= msec;
        end
        else if(count ==1 && state ==2 && en)begin
            cmin <= next_cmin;
            csec <= next_csec;
            ctensec <= next_ctensec;
            cmsec <= next_cmsec;
        end
    end

end
always@(*)begin//changing number in setting state
    if(state == SETTING && input_number_down)begin
        if(setnumber == 0)begin
           if(minute == 0)next_minute = 1;
           else next_minute = 0;
            next_sec = sec;
            next_tensec = tensec;
            next_msec = msec;
        end
        else if(setnumber == 1)begin
           if(tensec == 5)next_tensec = 0;
           else next_tensec = tensec + 1;
           next_sec = sec;
            next_msec = msec;
            next_minute = minute;
        end
        else if(setnumber == 2)begin
           if(sec == 9)next_sec = 0;
           else next_sec = sec + 1;
            next_tensec = tensec;
            next_msec = msec;
            next_minute = minute;
        end
        else if(setnumber == 3)begin
           if(msec == 9)next_msec = 0;
           else next_msec = msec + 1;
           next_sec = sec;
            next_tensec = tensec;
            next_minute = minute;
        end 
        else begin
            next_sec = sec;
            next_tensec = tensec;
            next_msec = msec;
            next_minute = minute;
        end         
    end
    else begin
        next_sec = sec;
        next_tensec = tensec;
        next_msec = msec;
        next_minute = minute;
    end
end

always@(*)begin//set dir in DIRECTION state
    if(counting_down && !state)next_dir = ~dir;
    else next_dir = dir;
end

always@(*)begin
    if(state == SETTING)begin
        if(dir==0)begin
            next_cmin =  minute;
            next_csec = sec;
            next_ctensec = tensec;
            next_cmsec = msec;
        end
        else begin
            next_cmin =  0;
            next_csec = 0;
            next_ctensec = 0;
            next_cmsec = 0;
        end
    end
    if(state == COUNT  && dir)begin
         if (cmin == minute && ctensec == tensec && csec == sec && cmsec == msec) begin
       next_cmin = cmin;
    next_csec = csec;
    next_ctensec = ctensec;
    next_cmsec = cmsec;
   end
   else if (cmin == 0 && ctensec == 5 && csec == 9 && cmsec == 9) begin
       next_cmin = cmin + 1;
    next_csec = 0;
    next_ctensec = 0;
    next_cmsec = 0;
   end
   else if (csec == 4'd9 && cmsec == 4'd9) begin
       next_cmin = cmin;
    next_csec = 0;
    next_ctensec = ctensec + 1;
    next_cmsec = 0;
   end
   else if (cmsec == 4'd9) begin
       next_cmin = cmin;
    next_csec = csec + 1;
    next_ctensec = ctensec;
    next_cmsec = 0;
   end
   else begin
       next_cmin = cmin;
    next_csec = csec;
    next_ctensec = ctensec;
    next_cmsec = cmsec+1;
   end
    end
    else if(state == COUNT  && dir==0)begin
        if (cmin == 0 && ctensec == 0 && csec == 0 && cmsec == 0) begin
       next_cmin = cmin;
    next_csec = csec;
    next_ctensec = ctensec;
    next_cmsec = cmsec;
   end
   else if (!cmsec&& !ctensec && !csec) begin
       next_cmin = cmin - 1;
    next_csec = 9;
    next_ctensec = 5;
    next_cmsec = 9;
   end
   else if (!csec && !cmsec) begin
       next_cmin = cmin;
    next_csec = 9;
    next_ctensec = ctensec - 1;
    next_cmsec = 9;
   end
   else if (!cmsec) begin
       next_cmin = cmin;
    next_csec = csec - 1;
    next_ctensec = ctensec;
    next_cmsec = 9;
   end
   else begin
       next_cmin = cmin;
    next_csec = csec;
    next_ctensec = ctensec;
    next_cmsec = cmsec - 1;
   end
    end
    else begin
        next_cmin = cmin;
     next_csec = csec;
     next_ctensec = ctensec;
     next_cmsec = cmsec;
    end
end

assign ledact=refresh_counter[19:18];//make suitable frequency for seven segment
assign led0 = ~dir; //led0 for dir

always@(posedge clk or posedge rst)begin//make a onesecound counter
    if(rst)begin
         oneseccounter <= 0;
    end
    else begin
        if(oneseccounter >= 10000000)
             oneseccounter <= 0;
        else
            oneseccounter <= oneseccounter+1;
    end
end

assign count=oneseccounter==10000000?1:0;


always@(*)begin
    case(ledact)
        2'b00:begin
            DIGIT=4'b0111;
            if(state == 0)value = 10;
            else if (state == 1)value = minute;
            else value = cmin;
        end
        2'b01:begin
            DIGIT=4'b1011;
            if(state == 0)value = 10;
            else if (state ==1)value = tensec;
            else value = ctensec;
        end
        2'b10:begin
            DIGIT=4'b1101;
            if(state == 0)value = 10;
            else if (state == 1)value = sec;
            else value = csec;
        end
        2'b11:begin
            DIGIT=4'b1110;
            if(state == 0)value = 10;
            else if (state == 1)value = msec;
            else value = cmsec;
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
        4'd10:DISPLAY=7'b0111111;
        default:DISPLAY=7'b1111111;
    endcase
end

endmodule