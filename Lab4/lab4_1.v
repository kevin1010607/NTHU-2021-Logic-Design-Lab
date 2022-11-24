// ex: num = 50000, freq = 100MHz/(num*2) = 1000Hz
`define S0 27'd50000000 // 1Hz -> speed0
`define S1 27'd25000000 // 2Hz -> speed1
`define S2 27'd12500000 // 4Hz -> speed2
`define UD 27'd50000 // 1000Hz -> refresh
`define P 27'd10000 // 5000Hz -> state, speed, pulse
module lab4_1(
    input clk,
    input rst,
    input en,
    input dir,
    input speed_up,
    input speed_down,
    output wire [3:0] DIGIT,
    output wire [6:0] DISPLAY,
    output wire max,
    output wire min);
    wire en_p, speed_up_p, speed_down_p, en_d, speed_up_d, speed_down_d;
    reg [1:0] state, next_state, speed, next_speed;
    reg [3:0] val3, val2, val1, val0, next_val3, next_val2, next_val1, next_val0;
    wire clk_s0, clk_s1, clk_s2, clk_u, clk_p;
    reg clk_s;
    // state parameter
    parameter PAUSE_INC = 2'b00;
    parameter PAUSE_DEC = 2'b01;
    parameter INC = 2'b10;
    parameter DEC = 2'b11;
    // speed parameter
    parameter SPEED0 = 2'b00;
    parameter SPEED1 = 2'b01;
    parameter SPEED2 = 2'b10;

    // clk
    clock_divider #(`S0) cs0(clk, clk_s0);
    clock_divider #(`S1) cs1(clk, clk_s1);
    clock_divider #(`S2) cs2(clk, clk_s2);
    clock_divider #(`UD) cud(clk, clk_u);
    clock_divider #(`P) cp(clk, clk_p);
    always @* begin
        clk_s = clk_s0;
        case(speed)
            SPEED0: clk_s = clk_s0;
            SPEED1: clk_s = clk_s1;
            SPEED2: clk_s = clk_s2;
        endcase
    end
    // debounced and generate onepulse
    debounce e_d(en_d, en, clk);
    debounce up_d(speed_up_d, speed_up, clk);
    debounce down_d(speed_down_d, speed_down, clk);
    onepulse e_p(en_d, clk_p, en_p);
    onepulse up_p(speed_up_d, clk_p, speed_up_p);
    onepulse down_p(speed_down_d, clk_p, speed_down_p);
    // DIGIT, DISPLAY
    Display d(clk_u, val0, val1, val2, val3, DIGIT, DISPLAY);
    // state, speed, val3, val2
    always @(posedge clk_p, posedge rst) begin
        if(rst == 1'b1) begin
            state <= PAUSE_INC;
            speed <= SPEED0;
            val3 <= 4'd0;
            val2 <= 4'd10;
        end else begin
            state <= next_state;
            speed <= next_speed;
            val3 <= next_val3;
            val2 <= next_val2;
        end
    end
    // val1, val0
    always @(posedge clk_s, posedge rst) begin
        if(rst == 1'b1) begin
            val1 <= 4'd0;
            val0 <= 4'd0;
        end else begin
            val1 <= next_val1;
            val0 <= next_val0;
        end
    end
    // next_state, next_val2
    always @* begin
        next_state = state;
        next_val2 = val2;
        case(state)
            PAUSE_INC: begin
                if(en_p == 1'b1) next_state = INC;
            end
            PAUSE_DEC: begin
               if(en_p == 1'b1) next_state = DEC;
            end
            INC: begin
                if(en_p==1'b1 && {val1, val0}!={4'd9, 4'd9}) begin
                    next_state = PAUSE_INC;
                end else if(dir == 1'b1) begin
                    next_state = DEC;
                    next_val2 = 4'd11;
                end
            end
            DEC: begin
                if(en_p==1'b1 && {val1, val0}!=8'd0) begin
                    next_state = PAUSE_DEC;
                end else if(dir == 1'b0) begin
                    next_state = INC;
                    next_val2 = 4'd10;
                end
            end
        endcase
    end
    // next_speed, next_val3;
    always @* begin
        next_speed = speed;
        next_val3 = val3;
        case(speed)
            SPEED0: begin
                if(speed_up_p == 1'b1) begin
                    next_speed = SPEED1;
                    next_val3 = 4'd1;
                end
            end
            SPEED1: begin
                if(speed_up_p == 1'b1) begin
                    next_speed = SPEED2;
                    next_val3 = 4'd2;
                end else if(speed_down_p == 1'b1) begin
                    next_speed = SPEED0;
                    next_val3 = 4'd0;
                end
            end
            SPEED2: begin
                if(speed_down_p == 1'b1) begin
                    next_speed = SPEED1;
                    next_val3 = 4'd1;
                end
            end
        endcase
    end 
    // next_val1, next_val0
    always @* begin
        next_val1 = val1;
        case(state)
            INC: begin
                if(val0==4'd9 && val1!=4'd9) next_val1 = val1+1'b1;
            end
            DEC: begin
                if(val0==4'd0 && val1!=4'd0) next_val1 = val1-1'b1;
            end
        endcase
    end
    always @* begin
        next_val0 = val0;
        case(state)
            INC: begin
                if(val0==4'd9 && val1!=4'd9) next_val0 = 4'd0;
                else if(val0 != 4'd9) next_val0 = val0+1'b1;
            end
            DEC: begin
                if(val0==4'd0 && val1!=4'd0) next_val0 = 4'd9;
                else if(val0 != 4'd0) next_val0 = val0-1'b1;
            end
        endcase
    end
    // max, min
    assign max = {val1, val0}=={4'd9, 4'd9};
    assign min = {val1, val0}==8'd0;
endmodule

module Display(
    input clk,
    input [3:0] val0,
    input [3:0] val1,
    input [3:0] val2,
    input [3:0] val3,
    output reg [3:0] DIGIT,
    output reg [6:0] DISPLAY);
    reg [3:0] val, next_val, next_DIGIT;
    // DIGIT, val
    always @(posedge clk) begin
        val <= next_val;
        DIGIT <= next_DIGIT;
    end
    // next_DIGIT, next_val
    always @* begin
        next_val = val0;
        next_DIGIT = 4'b1110;
        case(DIGIT)
            4'b1110: begin
                next_val = val1;
                next_DIGIT = 4'b1101;
            end
            4'b1101: begin
                next_val = val2;
                next_DIGIT = 4'b1011;
            end
            4'b1011: begin
                next_val = val3;
                next_DIGIT = 4'b0111;
            end
            4'b0111: begin
                next_val = val0;
                next_DIGIT = 4'b1110;
            end
        endcase
    end
    // DISPLAY
    always @* begin
        DISPLAY = 7'b111_1111;
        case(val)
            4'd0: DISPLAY = 7'b100_0000;
            4'd1: DISPLAY = 7'b111_1001;
            4'd2: DISPLAY = 7'b010_0100;
            4'd3: DISPLAY = 7'b011_0000;
            4'd4: DISPLAY = 7'b001_1001;
            4'd5: DISPLAY = 7'b001_0010;
            4'd6: DISPLAY = 7'b000_0010;
            4'd7: DISPLAY = 7'b111_1000;
            4'd8: DISPLAY = 7'b000_0000;
            4'd9: DISPLAY = 7'b001_0000;
            4'd10: DISPLAY = 7'b101_1100; // count up
            4'd11: DISPLAY = 7'b110_0011; // count down
        endcase
    end
endmodule

module clock_divider #(parameter s=`UD)(
    input clk,
    output wire clk_div);
    reg [26:0] cnt = 0, next_cnt;
    reg state = 0, next_state;
    // state, cnt
    always @(posedge clk) begin
        state <= next_state;
        cnt <= next_cnt;
    end
    // next_state
    always @* begin
        next_state = state;
        if(cnt == s-1'b1) next_state = ~state;
    end
    // next_cnt
    always @* begin
        next_cnt = cnt+1'b1;
        if(cnt == s-1'b1) next_cnt = 27'd0;
    end
    // clk_div
    assign clk_div = state;
endmodule
