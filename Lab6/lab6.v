module lab06(
    input clk,
    input rst,
    inout PS2_CLK,
    inout PS2_DATA,
    output wire [3:0] DIGIT,
    output wire [6:0] DISPLAY,
    output reg [15:0] LED
    );

    // parameter for key_code
    parameter [8:0] KEY_CODE_1 = 9'b0_0110_1001;
    parameter [8:0] KEY_CODE_2 = 9'b0_0111_0010;
    // paremeter for state
    parameter [2:0] IDLE = 3'b000;
    parameter [2:0] GETON = 3'b001;
    parameter [2:0] PAYMENT = 3'b010;
    parameter [2:0] REFUEL = 3'b011;
    parameter [2:0] MOVE = 3'b100;
    parameter [2:0] GETOFF = 3'b101;
    // parameter for bus_pos
    parameter [2:0] G1 = 3'd0;
    parameter [2:0] G2 = 3'd3;
    parameter [2:0] G3 = 3'd6;
    parameter [2:0] B1 = 3'd0;
    parameter [2:0] B2 = 3'd6;
    // parameter for dir
    parameter L = 1'b0;
    parameter R = 1'b1;
    // parameter for cnt
    parameter CNT = {27{1'b1}};

    reg [2:0] state, next_state, bus_pos, next_bus_pos;
    reg [1:0] wait_B1, wait_B2, next_wait_B1, next_wait_B2, bus_people, next_bus_people;
    reg [7:0] gas, next_gas, income, next_income;
    reg [15:0] nums, next_nums, next_LED;
    reg dir, next_dir;
    reg [26:0] cnt, next_cnt;
    wire [7:0] gas_BCD, income_BCD;
    
    wire [511:0] key_down;
    wire [8:0] last_change;
    wire been_ready;

    SevenSegment seven_seg(
        .display(DISPLAY),
        .digit(DIGIT),
        .nums(nums),
        .clk(clk)
    );
    BCD b1(
        .binary(gas),
        .BCD(gas_BCD)
    );
    BCD b2(
        .binary(income),
        .BCD(income_BCD)
    );
    KeyboardDecoder key_de(
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(been_ready),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );

    // state, bus_pos, wait_B1, wait_B2, bus_people, gas, income, nums, LED, dir, cnt
    always @(posedge clk, posedge rst) begin
        if(rst)begin
            state <= IDLE;
            bus_pos <= 3'd0;
            wait_B1 <= 2'd0;
            wait_B2 <= 2'd0;
            bus_people <= 2'd0;
            gas <= 8'd0;
            income <= 8'd0;
            nums <= 16'd0;
            LED <= {15'd0, 1'b1};
            dir <= L;
            cnt <= 27'd0;
        end else begin
            state <= next_state;
            bus_pos <= next_bus_pos;
            wait_B1 <= next_wait_B1;
            wait_B2 <= next_wait_B2;
            bus_people <= next_bus_people;
            gas <= next_gas;
            income <= next_income;
            nums <= next_nums;
            LED <= next_LED;
            dir <= next_dir;
            cnt <= next_cnt;
        end
    end
    // next_state
    always @* begin
        next_state = state;
        if(cnt == CNT) begin
            case(state)
                IDLE: begin
                    if(wait_B1 && wait_B2) next_state = GETON;
                    else if(wait_B1) next_state = (bus_pos==B1)?(GETON):(REFUEL);
                    else if(wait_B2) next_state = (bus_pos==B2)?(GETON):(REFUEL);
                end
                GETON: begin
                    next_state = PAYMENT;
                end
                PAYMENT: begin
                    next_state = REFUEL;
                end
                REFUEL: begin
                   if(gas==8'd20 || income==8'd0) next_state = MOVE; 
                end
                MOVE: begin
                    if(bus_people != 2'd0) begin
                        if(next_bus_pos==G1 || next_bus_pos==G3) next_state = GETOFF;
                        else if(next_bus_pos == G2) next_state = REFUEL;
                    end else begin
                        if(next_bus_pos==B1 || next_bus_pos==B2) next_state = GETON;
                    end
                end
                GETOFF: begin
                    if(next_bus_people > 2'd0) next_state = GETOFF;
                    else if(wait_B1 && wait_B2) next_state = GETON;
                    else if(wait_B1) next_state = (bus_pos==B1)?(GETON):(REFUEL);
                    else if(wait_B2) next_state = (bus_pos==B2)?(GETON):(REFUEL);
                    else next_state = IDLE;
                end
            endcase
        end
    end
    // next_bus_pos
    always @* begin
        next_bus_pos = bus_pos;
        if(cnt == CNT) begin
            case(state)
                REFUEL: if(gas==8'd20 || income==8'd0) next_bus_pos = (dir==L)?(bus_pos+3'd1):(bus_pos-3'd1);
                MOVE: next_bus_pos = (dir==L)?(bus_pos+3'd1):(bus_pos-3'd1);
            endcase
        end
    end
    // next_wait_B1, next_wait_B2
    always @* begin
        next_wait_B1 = wait_B1;
        next_wait_B2 = wait_B2;
        if(state==GETON && cnt==CNT) begin
            if(bus_pos == B1) next_wait_B1 = 2'd0;
            else next_wait_B2 = 2'd0;
        end else if(been_ready && key_down[last_change]==1'b1) begin
            if(last_change==KEY_CODE_1 && wait_B1<2'd2) next_wait_B1 = wait_B1+2'd1;
            else if(last_change==KEY_CODE_2 && wait_B2<2'd2) next_wait_B2 = wait_B2+2'd1;
        end
    end
    // next_bus_people
    always @* begin
        next_bus_people = bus_people;
        if(cnt == CNT) begin
            case(state)
                GETON: begin
                    if(wait_B1 && bus_pos==B1) next_bus_people = wait_B1;
                    else if(wait_B2 && bus_pos==B2) next_bus_people = wait_B2;
                end
                GETOFF: begin
                    if(bus_people > 2'd0) next_bus_people = bus_people-2'd1;
                end
            endcase
        end
    end
    // next_gas
    always @* begin
        next_gas = gas;
        if(cnt == CNT) begin
            case(state)
                MOVE: if(next_bus_pos==G1 || next_bus_pos==G2 || next_bus_pos==G3) next_gas = gas-(bus_people*8'd5);
                REFUEL: if(!(gas==8'd20 || income==8'd0)) next_gas = (gas>8'd10)?(8'd20):(gas+8'd10);
            endcase
        end
    end
    // next_income
    always @* begin
        next_income = income;
        if(cnt == CNT) begin
            case(state)
                PAYMENT: begin
                    if(bus_pos == B1) begin
                        next_income = (income+bus_people*8'd30>8'd90)?(8'd90):(income+bus_people*8'd30);
                    end else begin
                        next_income = (income+bus_people*8'd20>8'd90)?(8'd90):(income+bus_people*8'd20);
                    end    
                end
                REFUEL: begin
                    if(!(gas==8'd20 || income==8'd0)) next_income = income-8'd10;
                end
            endcase
        end
    end
    // next_nums
    always @* begin
        next_nums = {gas_BCD, income_BCD};
    end
    // next_LED
    always @* begin
        next_LED = 16'd0;
        next_LED[bus_pos] = 1'b1;
        case(wait_B1)
            2'd1: next_LED[15] = 1'b1;
            2'd2: next_LED[15:14] = 2'b11;
        endcase
        case(wait_B2)
            2'd1: next_LED[12] = 1'b1;
            2'd2: next_LED[12:11] = 2'b11;
        endcase
        case(bus_people)
            2'd1: next_LED[10] = 1'b1;
            2'd2: next_LED[10:9] = 2'b11;
        endcase
    end
    // next_dir
    always @* begin
        next_dir = dir;
        if(bus_pos == B1) next_dir = L;
        else if(bus_pos == B2) next_dir = R;
    end
    // next_cnt
    always @* begin
        next_cnt = cnt+27'd1;
    end
endmodule

module BCD(
    input [7:0] binary,
    output reg [7:0] BCD);
    wire [7:0] b1, b2, b3, b4, b5, b6, b7, b8, b9;
    assign b1 = binary-8'd10;
    assign b2 = binary-8'd20;
    assign b3 = binary-8'd30;
    assign b4 = binary-8'd40;
    assign b5 = binary-8'd50;
    assign b6 = binary-8'd60;
    assign b7 = binary-8'd70;
    assign b8 = binary-8'd80;
    assign b9 = binary-8'd90;
    // BCD
    always @* begin
        BCD = binary;
        if(binary < 8'd10) BCD = binary;
        else if(binary < 8'd20) BCD = {4'd1, b1[3:0]};
        else if(binary < 8'd30) BCD = {4'd2, b2[3:0]};
        else if(binary < 8'd40) BCD = {4'd3, b3[3:0]};
        else if(binary < 8'd50) BCD = {4'd4, b4[3:0]};
        else if(binary < 8'd60) BCD = {4'd5, b5[3:0]};
        else if(binary < 8'd70) BCD = {4'd6, b6[3:0]};
        else if(binary < 8'd80) BCD = {4'd7, b7[3:0]};
        else if(binary < 8'd90) BCD = {4'd8, b8[3:0]};
        else if(binary < 8'd100) BCD = {4'd9, b9[3:0]};
    end
endmodule

module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [15:0] nums,
	input wire clk
    );
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk) begin
    	clk_divider <= clk_divider + 15'b1;
    end
    
    always @ (posedge clk_divider[15]) begin
    	case (digit)
    		4'b1110 : begin
    			display_num <= nums[7:4];
    			digit <= 4'b1101;
    		end
    		4'b1101 : begin
				display_num <= nums[11:8];
				digit <= 4'b1011;
			end
    		4'b1011 : begin
				display_num <= nums[15:12];
				digit <= 4'b0111;
			end
    		4'b0111 : begin
				display_num <= nums[3:0];
				digit <= 4'b1110;
			end
    		default : begin
				display_num <= nums[3:0];
				digit <= 4'b1110;
			end				
    	endcase
    end
    
    always @ (*) begin
    	case (display_num)
    		0 : display = 7'b1000000;	//0000
			1 : display = 7'b1111001;   //0001                                                
			2 : display = 7'b0100100;   //0010                                                
			3 : display = 7'b0110000;   //0011                                             
			4 : display = 7'b0011001;   //0100                                               
			5 : display = 7'b0010010;   //0101                                               
			6 : display = 7'b0000010;   //0110
			7 : display = 7'b1111000;   //0111
			8 : display = 7'b0000000;   //1000
			9 : display = 7'b0010000;	//1001
			default : display = 7'b1111111;
    	endcase
    end
    
endmodule