`define FRONT   2'd0
`define LEFT    2'd1
`define RIGHT   2'd2
`define STOP    2'd3

// *************** lab9.v *************** //

module Lab9(
    input clk,
    input rst,
    input echo,
    input left_track,
    input right_track,
    input mid_track,
    output trig,
    output IN1,
    output IN2,
    output IN3, 
    output IN4,
    output left_pwm,
    output right_pwm,
    output [3:0] DIGIT,
    output [6:0] DISPLAY,
    output [15:0] LED
    // You may modify or add more input/ouput yourself.
);
    // We have connected the motor, tracker_sensor and sonic_top modules in the template file for you.
    // TODO: control the motors with the information you get from ultrasonic sensor and 3-way track sensor.

    reg [1:0] mode;
    wire [19:0] distance;
    wire [1:0] tracker_state;

    // mode
    always @(posedge clk, posedge rst) begin
        if(rst) mode <= `STOP;
        else mode <= (distance<20'd15)?(`STOP):(tracker_state);
    end
    
    motor A(
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .pwm({left_pwm, right_pwm}),
        .l_IN({IN1, IN2}),
        .r_IN({IN3, IN4})
    );

    sonic_top B(
        .clk(clk), 
        .rst(rst), 
        .Echo(echo), 
        .Trig(trig),
        .distance(distance)
    );

    tracker_sensor C(
        .clk(clk), 
        .reset(rst), 
        .left_track(~left_track), 
        .right_track(~right_track),
        .mid_track(~mid_track),
        .state(tracker_state)
    );

    wire [15:0] nums;
    wire [7:0] dis_BCD;
    reg [7:0] dis;

    always @* begin
        if(distance >= 20'd100) dis = {4'd10, 4'd10};
        else dis = dis_BCD;
    end

    assign nums = {2'd0, mode, 4'd10, dis};
    assign LED = {13'd0, ~right_track, ~mid_track, ~left_track};

    BCD b(
        .binary(distance[7:0]),
        .BCD(dis_BCD)
    );

    // SevenSegment
    SevenSegment ss(
        .display(DISPLAY),
        .digit(DIGIT),
        .nums(nums),
        .clk(clk)
    );

endmodule

// *************** lab9.v *************** //


// *************** moter.v *************** //

// This module take "mode" input and control two motors accordingly.
// clk should be 100MHz for PWM_gen module to work correctly.
// You can modify / add more inputs and outputs by yourself.
module motor(
    input clk,
    input rst,
    input [1:0]mode,
    output  [1:0]pwm,
    output reg [1:0]r_IN,
    output reg [1:0]l_IN
);

    reg [9:0]next_left_motor, next_right_motor;
    reg [9:0]left_motor, right_motor;
    wire left_pwm, right_pwm;

    motor_pwm m0(clk, rst, left_motor, left_pwm);
    motor_pwm m1(clk, rst, right_motor, right_pwm);

    assign pwm = {left_pwm,right_pwm};

    // TODO: trace the rest of motor.v and control the speed and direction of the two motors
    parameter SLOW = 10'd600;
    parameter FAST = 10'd730;
    parameter STOP = 10'd0;

    // left_motor, right_motor
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            left_motor <= 10'd0;
            right_motor <= 10'd0;
        end else begin
            left_motor <= next_left_motor;
            right_motor <= next_right_motor;
        end
    end

    // next_left_motor, next_right_motor, r_IN, l_IN
    always @* begin
        case(mode)
            `FRONT: begin
                next_left_motor = FAST;
                next_right_motor = FAST;
                l_IN = 2'b10;
                r_IN = 2'b10;
            end
            `LEFT: begin
                next_left_motor = SLOW;
                next_right_motor = FAST;
                l_IN = 2'b10;
                r_IN = 2'b10;
            end
            `RIGHT: begin
                next_left_motor = FAST;
                next_right_motor = SLOW;
                l_IN = 2'b10;
                r_IN = 2'b10;
            end
            `STOP: begin
                next_left_motor = 10'd0;
                next_right_motor = 10'd0;
                l_IN = 2'b00;
                r_IN = 2'b00;
            end
        endcase
    end
    
endmodule

module motor_pwm (
    input clk,
    input reset,
    input [9:0]duty,
	output pmod_1 //PWM
);
        
    PWM_gen pwm_0 ( 
        .clk(clk), 
        .reset(reset), 
        .freq(32'd25000),
        .duty(duty), 
        .PWM(pmod_1)
    );

endmodule

//generte PWM by input frequency & duty cycle
module PWM_gen (
    input wire clk,
    input wire reset,
	input [31:0] freq,
    input [9:0] duty,
    output reg PWM
);
    wire [31:0] count_max = 100_000_000 / freq;
    wire [31:0] count_duty = count_max * duty / 1024;
    reg [31:0] count;
        
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            PWM <= 0;
        end else if (count < count_max) begin
            count <= count + 1;
            if(count < count_duty)
                PWM <= 1;
            else
                PWM <= 0;
        end else begin
            count <= 0;
            PWM <= 0;
        end
    end
endmodule

// *************** motor.v *************** //


// *************** sonic.v *************** //

// sonic_top is the module to interface with sonic sensors
// clk = 100MHz
// <Trig> and <Echo> should connect to the sensor
// <distance> is the output distance in cm
module sonic_top(clk, rst, Echo, Trig, distance);
	input clk, rst, Echo;
	output Trig;
    output [19:0] distance;

	wire[19:0] dis;
    wire clk1M;
	wire clk_2_17;

    assign distance = dis;

    div clk1(clk ,clk1M);
	TrigSignal u1(.clk(clk), .rst(rst), .trig(Trig));
	PosCounter u2(.clk(clk1M), .rst(rst), .echo(Echo), .distance_count(dis));
 
endmodule

module PosCounter(clk, rst, echo, distance_count); 
    input clk, rst, echo;
    output[19:0] distance_count;

    parameter S0 = 2'b00;
    parameter S1 = 2'b01; 
    parameter S2 = 2'b10;
    
    wire start, finish;
    reg[1:0] curr_state, next_state;
    reg echo_reg1, echo_reg2;
    reg[19:0] count, distance_register;
    wire[19:0] distance_count; 

    always@(posedge clk) begin
        if(rst) begin
            echo_reg1 <= 0;
            echo_reg2 <= 0;
            count <= 0;
            distance_register  <= 0;
            curr_state <= S0;
        end
        else begin
            echo_reg1 <= echo;   
            echo_reg2 <= echo_reg1; 
            case(curr_state)
                S0:begin
                    if (start) curr_state <= next_state; //S1
                    else count <= 0;
                end
                S1:begin
                    if (finish) curr_state <= next_state; //S2
                    else count <= count + 1;
                end
                S2:begin
                    distance_register <= count;
                    count <= 0;
                    curr_state <= next_state; //S0
                end
            endcase
        end
    end

    always @(*) begin
        case(curr_state)
            S0:next_state = S1;
            S1:next_state = S2;
            S2:next_state = S0;
            default:next_state = S0;
        endcase
    end

    assign start = echo_reg1 & ~echo_reg2;  
    assign finish = ~echo_reg1 & echo_reg2;

    // TODO: trace the code and calculate the distance, output it to <distance_count>
    // distance_count
    assign distance_count = distance_register*34/2000;

endmodule

// send trigger signal to sensor
module TrigSignal(clk, rst, trig);
    input clk, rst;
    output trig;

    reg trig, next_trig;
    reg[23:0] count, next_count;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
            trig <= 0;
        end
        else begin
            count <= next_count;
            trig <= next_trig;
        end
    end
    // count 10us to set trig high and wait for 100ms
    always @(*) begin
        next_trig = trig;
        next_count = count + 1;
        if(count == 999)
            next_trig = 0;
        else if(count == 24'd9999999) begin
            next_trig = 1;
            next_count = 0;
        end
    end
endmodule

// clock divider for T = 1us clock
module div(clk ,out_clk);
    input clk;
    output out_clk;
    reg out_clk;
    reg [6:0]cnt;
    
    always @(posedge clk) begin   
        if(cnt < 7'd50) begin
            cnt <= cnt + 1'b1;
            out_clk <= 1'b1;
        end 
        else if(cnt < 7'd100) begin
	        cnt <= cnt + 1'b1;
	        out_clk <= 1'b0;
        end
        else if(cnt == 7'd100) begin
            cnt <= 0;
            out_clk <= 1'b1;
        end
    end
endmodule

// *************** sonic.v *************** //


// *************** tracker_sensor.v *************** //

module tracker_sensor(clk, reset, left_track, right_track, mid_track, state);
    input clk;
    input reset;
    input left_track, right_track, mid_track;
    output reg [1:0] state;

    // 0 for white, 1 for black

    // TODO: Receive three tracks and make your own policy.
    // Hint: You can use output state to change your action.
    // state
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= `STOP;
        end else begin
            case({left_track, mid_track, right_track})
                // 3'b000: state <= state;
                3'b001: state <= `RIGHT;
                3'b010: state <= `FRONT;
                3'b011: state <= `RIGHT;
                3'b100: state <= `LEFT;
                // 3'b101: state <= state;
                3'b110: state <= `LEFT;
                3'b111: state <= `STOP;
            endcase
        end
    end

endmodule

// *************** tracker_sensor.v *************** //

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
        else BCD = {8'd0};
    end
endmodule
