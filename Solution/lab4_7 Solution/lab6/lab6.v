module clk_divider(clk, clk_div);
	parameter n=25;
	input clk;
	output clk_div;
	
	reg [n-1:0]num;
	wire [n-1:0]next_num;
	
	always@(posedge clk)begin
		num <= next_num;
	end
	
	assign next_num = num + 1;
	assign clk_div = num[n-1];
	
endmodule

`define SEG0  4'b1110
`define SEG1  4'b1101
`define SEG2  4'b1011
`define SEG3  4'b0111

`define STAY_wait  3'd0
`define STAY_getoff  3'd1
`define STAY_geton  3'd2
`define STAY_refuel  3'd3
`define GO  3'd4

`define DOWN  1'd0
`define UP  1'd1


module lab6(
	input clk,
	input rst,
	inout PS2_DATA,
	inout PS2_CLK,
	output reg[15:0]LED,
	output reg[3:0]DIGIT,
	output reg[6:0]DISPLAY
);

	wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;
	
	reg[2:0] state,next_state;
	wire[15:0]next_LED;
	wire clk_div26,clk_div10;
	
	wire next_enable;
	reg [3:0]next_DIGIT;
	reg [1:0]B1P,B2P,next_B1P,next_B2P; // NUMBER of Passenger
	reg [2:0]position,next_position;
	reg [1:0]BusP,next_BusP;
	reg [4:0]BusG,next_BusG;
	reg DIR,next_DIR; // UP / DOWN
	reg [6:0] revenue, next_revenue;
	reg [27:0] counter_1,next_counter_1,counter_2,next_counter_2;
	reg[15:0] num1,num2,posled,BusPnum;
	reg [3:0]next_seg1_value,next_seg0_value,seg0_value,seg1_value,value,seg2_value,next_seg2_value,seg3_value,next_seg3_value;

	clk_divider #(26)clkdiv26(clk, clk_div26);
	clk_divider #(10)clkdiv10(clk, clk_div10);
	
	parameter [8:0]KEY_CODES1 = 9'b0_0110_1001;
    parameter [8:0]KEY_CODES2 = 9'b0_0111_0010;

	always@(posedge clk_div26 or posedge rst)begin
		if(rst)begin
			DIR <= 1'd1;
		end
		else begin
			DIR <= next_DIR;
		end
	end
	always@(posedge clk_div26 or posedge rst)begin
		if(rst)begin
			position <= 3'd0;
		end
		else begin
			position <= next_position;
		end
	end
	
	always@(posedge clk_div26 or posedge rst)begin
		if(rst)begin
			BusP <= 2'd0;
			
		end
		else begin
			BusP <= next_BusP;
		end
	end
	always@(posedge clk_div26 or posedge rst)begin
		if(rst)begin
			revenue <= 7'd0;
			BusG <= 5'd0;
		end
		else begin
			revenue <= next_revenue;
			BusG <= next_BusG;
		end
	end
	
	always@(posedge clk_div26 or posedge rst)begin
		if(rst)begin
			state <= `STAY_wait;
		end
		else begin
			state <= next_state;
		end
	end
	
	//------------------------------------------------------------------------------------------

	always@(*)begin
	    next_position = position;
	    next_B1P = B1P;
	    next_B2P = B2P;
		next_BusG =  BusG;
		next_BusP = BusP;
		next_DIR = DIR;
		next_revenue = revenue;
		next_state = state;
		
        if( been_ready &&  key_down[last_change] )begin     
            if(last_change==KEY_CODES1 && B1P<2)next_B1P = B1P + 1;
            else if(last_change==KEY_CODES2 && B2P<2)next_B2P = B2P + 1;
        end

       case(state)
            `STAY_wait:begin
                if(position == 0)next_DIR =`UP;
                else next_DIR =`DOWN;

                if((B1P>0 && position == 0) || (B2P>0 && position == 6))begin
					next_state =  `STAY_geton ;
					if (position == 6)next_BusP = B2P;
					else next_BusP = B1P;
					
				end
                else if((B2P>0 && position == 0) || (B1P>0 && position == 6))next_state =  `GO ;
                else next_state = `STAY_wait;	
                
            end
            `STAY_geton:begin
                if(position == 0)next_DIR =`UP;
                else next_DIR =`DOWN;
				
				if(BusG<20)next_state =  `STAY_refuel ;
				else next_state = `GO;
				
                if(position == 0)next_revenue = (revenue+30*BusP) > 90 ? 90 : (revenue+30*BusP);
                else next_revenue = (revenue+20*BusP) > 90 ? 90 : (revenue+20*BusP);
				
             end
            `STAY_getoff:begin
                 if(position == 0)next_DIR =`UP;
                 else next_DIR =`DOWN;
                 
                 if (BusP>0)next_BusP = BusP-1;	
				 else begin
					 if((B1P>0 && position == 0)||(B2P>0 && position == 6))begin
						next_state =  `STAY_geton ;
						if (position == 6)next_BusP = B2P;
						else next_BusP = B1P;
						
					end
					else next_state = `STAY_wait ; 
				end 
					 
				
             end
             
             `STAY_refuel:begin	
                    if(revenue>=10)begin
                        next_BusG = (BusG + 10) > 20 ? 20 : (BusG + 10);
                        next_revenue = revenue-10;
                        
                    end
                    if (BusG + 10 >= 20 || revenue<=10)begin
                         next_state = `GO;
                    end	
             end
             
             `GO:begin
                 if((position == 5  && DIR == `UP)|| (position == 4 && DIR == `DOWN && BusP>0)|| (position == 2 && DIR == `UP && BusP>0)|| (position == 1 && DIR == `DOWN ))begin
                    if(BusP>0 && (position == 5 || position == 1))next_state = `STAY_getoff;
                    else if((position == 5  && B2P>0)|| (position == 1  && B1P>0))begin
						next_state =  `STAY_geton ;
						if (position == 5)next_BusP = B2P;
						else next_BusP = B1P;
					end	
                    else if (position == 4 || position == 2)next_state = `STAY_refuel;
					
                    else next_state = `STAY_wait ; 
                    
                    next_BusG = BusG - BusP*5;
                    
                end	
    
                if(DIR == `UP)next_position = position + 1;
                else next_position = position - 1;
             end
        endcase  

	end
	
	KeyboardDecoder key (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);

	always@(posedge clk or posedge rst)begin
		if(rst)begin
			B1P <= 2'd0;
			counter_1<=0;
		end
		else begin
            if(counter_1>=28'b0001_0000_0000_0000_0000_0000_0000)begin
                if(state==`STAY_geton && position == 0 && B1P>0) B1P<= 0;
                counter_1<= 28'b0;
            end
            else begin   
                B1P<= next_B1P;  
                counter_1<= counter_1+1;
            end
		end
	end
	
	always@(posedge clk or posedge rst)begin
		if(rst)begin
			B2P <= 2'd0;
			counter_2<=0;
		end
		else begin
            if(counter_2>=28'b0001_0000_0000_0000_0000_0000_0000)begin
                if(state==`STAY_geton && position == 6 && B2P>0) B2P<= 0;
                counter_2<= 28'b0;
            end
            else begin
                B2P<= next_B2P;
                
                counter_2<= counter_2+1;
            end
		end
	end

	always@(*)begin
		LED = num1 | num2 | posled | BusPnum;
	end

	always@(*)begin
		BusPnum = 16'b0000_0000_0000_0000;
		case(BusP)
			2'd0:BusPnum = 16'b0000_0000_0000_0000;
			2'd1:BusPnum = 16'b0000_0100_0000_0000;
			2'd2:BusPnum = 16'b0000_0110_0000_0000;
		endcase
		
		num1 = 16'b0000_0000_0000_0000;
		case(B1P)
			3'd0:num1 = 16'b0000_0000_0000_0000;
			3'd1:num1 = 16'b1000_0000_0000_0000;
			3'd2:num1 = 16'b1100_0000_0000_0000;
		endcase
		
		num2 = 16'b0000_0000_0000_0000;
		case(B2P)
			3'd0:num2 = 16'b0000_0000_0000_0000;
			3'd1:num2 = 16'b0001_0000_0000_0000;
			3'd2:num2 = 16'b0001_1000_0000_0000;
		endcase
		
		posled = 16'b0000_0000_0000_0000;
		case(position)
			4'd0:posled  = 16'b0000_0000_0000_0001;
			4'd1:posled  = 16'b0000_0000_0000_0010;
			4'd2:posled  = 16'b0000_0000_0000_0100;
			4'd3:posled  = 16'b0000_0000_0000_1000;
			4'd4:posled  = 16'b0000_0000_0001_0000;
			4'd5:posled  = 16'b0000_0000_0010_0000;
			4'd6:posled  = 16'b0000_0000_0100_0000;
		endcase
		
	end
				
	always@(posedge clk_div10 )begin
		DIGIT    <= next_DIGIT;
	end
	
	always@(*)begin		
		case(DIGIT)
			`SEG0:next_DIGIT = `SEG1;
			`SEG1:next_DIGIT = `SEG2;
			`SEG2:next_DIGIT = `SEG3;
			`SEG3:next_DIGIT = `SEG0;	
			default:next_DIGIT = `SEG0;		
		endcase
	end

	always@(*)begin
		DISPLAY = 7'b1111_111; 
			
		case(value)
			4'd0: DISPLAY = 7'b1000_000;
            4'd1: DISPLAY = 7'b1111_001;
            4'd2: DISPLAY = 7'b0100_100;
            4'd3: DISPLAY = 7'b0110_000;
            4'd4: DISPLAY = 7'b0011_001;
            4'd5: DISPLAY = 7'b0010_010;
            4'd6: DISPLAY = 7'b0000_010;
            4'd7: DISPLAY = 7'b1011_000;
            4'd8: DISPLAY = 7'b0000_000;
            4'd9: DISPLAY = 7'b0010_000;

			
		endcase
	end
	
	always@(*)begin
		value = seg0_value;
		case(DIGIT)
			`SEG0:value = seg0_value;
			`SEG1:value = seg1_value;
			`SEG2:value = seg2_value;
			`SEG3:value = seg3_value;					
		endcase
	end
	
	always@(posedge clk_div26 or posedge rst)begin
		if(rst)begin	
			seg0_value <= 4'd0; 
			seg1_value <= 4'd0;
			seg2_value <= 4'd0; 
			seg3_value <= 4'd0;

		end
		else begin
		    seg0_value <= next_revenue % 10;
            seg1_value <= next_revenue / 10;
            seg2_value <= next_BusG  % 10;
            seg3_value <= next_BusG / 10;
			
            		
		end
	end
	
endmodule
