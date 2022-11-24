module lab5(
    input clk,
    input rst, 
    input BTNL,
    input BTNR,
    input BTNU,
    input BTND,
    input BTNC,
    output reg [15:0] LED,
    output wire [3:0] DIGIT,
    output wire [6:0] DISPLAY);

    // state, person, amount
    reg [2:0] state, next_state;
    reg [3:0] person, next_person, amount, next_amount;
    // money, price
    reg [7:0] money, next_money, price, next_price;
    wire [7:0] next_money_BCD, next_price_BCD;
    // count_sec, count_clk
    reg [2:0] count_sec, next_count_sec;
    reg [11:0] count_clk, next_count_clk;
    // nums, LED
    reg [15:0] nums, next_nums, next_LED;
    // L, R, U, D, C, clk_div
    wire Ld, Rd, Ud, Dd, Cd, Lp, Rp, Up, Dp, Cp;
    wire clk_div;

    // parameter for state
    parameter IDLE = 3'b000;
    parameter TYPE = 3'b001;
    parameter AMOUNT = 3'b010;
    parameter PAYMENT = 3'b011;
    parameter RELEASE = 3'b100;
    parameter CHANGE = 3'b101;
    // parameter for person
    parameter C = 4'd12;
    parameter S = 4'd13;
    parameter A = 4'd14;

    // debounce and onepulse
    debounce d1(.pb_debounced(Ld), .pb(BTNL), .clk(clk_div));
    debounce d2(.pb_debounced(Rd), .pb(BTNR), .clk(clk_div));
    debounce d3(.pb_debounced(Ud), .pb(BTNU), .clk(clk_div));
    debounce d4(.pb_debounced(Dd), .pb(BTND), .clk(clk_div));
    debounce d5(.pb_debounced(Cd), .pb(BTNC), .clk(clk_div));
    onepulse p1(.pb_debounced(Ld), .clk(clk_div), .pb_1pulse(Lp));
    onepulse p2(.pb_debounced(Rd), .clk(clk_div), .pb_1pulse(Rp));
    onepulse p3(.pb_debounced(Ud), .clk(clk_div), .pb_1pulse(Up));
    onepulse p4(.pb_debounced(Dd), .clk(clk_div), .pb_1pulse(Dp));
    onepulse p5(.pb_debounced(Cd), .clk(clk_div), .pb_1pulse(Cp));
    // Display
    SevenSegment s(.display(DISPLAY), .digit(DIGIT), .nums(nums), .rst(rst), .clk(clk));
    // clk_div
    clock_divider c(.clk(clk), .clk_div(clk_div));
    // next_money_BCD, next_price_BCD
    BCD b1(.binary(next_money), .BCD(next_money_BCD));
    BCD b2(.binary(next_price), .BCD(next_price_BCD));

    // state, person, amount, money, price, count_sec, count_clk, nums, LED
    always @(posedge clk_div, posedge rst) begin
        if(rst) begin
            state <= IDLE;
            person <= C;
            amount <= 4'd1;
            money <= 8'd0;
            price <= 8'd0;
            count_sec <= 3'd0;
            count_clk <= 12'd2000;
            nums <= {4{4'd10}};
            LED <= 16'd0;
        end else begin
            state <= next_state;
            person <= next_person;
            amount <= next_amount;
            money <= next_money;
            price <= next_price;
            count_sec <= next_count_sec;
            count_clk <= next_count_clk;
            nums <= next_nums;
            LED <= next_LED;
        end
    end
    // next_state, next_person
    always @* begin
        next_state = state;
        next_person = person;
        case(state)
            IDLE: begin
                if(Lp) begin
                    next_state = TYPE;
                    next_person = C;
                end else if(Cp) begin
                    next_state = TYPE;
                    next_person = S;
                end else if(Rp) begin
                    next_state = TYPE;
                    next_person = A;
                end
            end
            TYPE: begin
                if(Up) next_state = AMOUNT;
                else if(Dp) next_state = IDLE;
                else if(Lp) next_person = C;
                else if(Cp) next_person = S;
                else if(Rp) next_person = A;
            end
            AMOUNT: begin
                if(Up) next_state = PAYMENT;
                else if(Dp) next_state = IDLE;
            end
            PAYMENT: begin
                if(money >= price) next_state = RELEASE;
                else if(Dp) next_state = CHANGE;
            end
            RELEASE: begin
                if(next_count_sec == 3'd5) next_state = CHANGE;
            end
            CHANGE: begin
                if(money==8'd0 && count_clk==12'd2000) next_state = IDLE;
            end
        endcase
    end
    // next_amount
    always @* begin
        next_amount = amount;
        case(state)
            TYPE: begin
                if(Up) next_amount = 4'd1;
            end
            AMOUNT: begin
                if(Lp && amount!=4'd1) next_amount = amount-4'd1;
                else if(Rp && amount!=4'd3) next_amount = amount+4'd1;
            end
        endcase
    end
    // next_money
    always @* begin
        next_money = money;
        case(state)
            AMOUNT: begin
                if(Up) next_money = 8'd0;
            end
            PAYMENT: begin
                if(money >= price) next_money = money-price;
                else if(Dp) next_money = money;
                else if(Lp) next_money = money+8'd1;
                else if(Cp) next_money = money+8'd5;
                else if(Rp) next_money = money+8'd10;
            end
            CHANGE: begin
                if(count_clk == 12'd2000) begin
                    if(money >= 8'd5) next_money = money-8'd5;
                    else next_money = money-8'd1;
                end
            end
        endcase
    end
    // next_price
    always @* begin
        next_price = price;
        case(state)
            IDLE: begin
                if(Lp) next_price = 8'd5;
                else if(Cp) next_price = 8'd10;
                else if(Rp) next_price = 8'd15;
            end
            TYPE: begin
                if(Lp) next_price = 8'd5;
                else if(Cp) next_price = 8'd10;
                else if(Rp) next_price = 8'd15;
            end
            AMOUNT: begin
                if(Up) next_price = price*amount;
            end
        endcase
    end
    // next_count_sec
    always @* begin
        next_count_sec = count_sec;
        case(state)
            PAYMENT: if(money >= price) next_count_sec = 3'd0;
            RELEASE: if(count_clk == 12'd2000) next_count_sec = count_sec+3'd1;
        endcase
    end
    // next_count_clk
    always @* begin
        next_count_clk = count_clk;
        case(state)
            IDLE: begin
                if(count_clk == 12'd2000) next_count_clk = 12'd1;
                else next_count_clk = count_clk+12'd1;
            end
            TYPE: begin
                if(Dp) next_count_clk = 12'd1;
            end
            AMOUNT: begin
                if(Dp) next_count_clk = 12'd1; 
            end
            PAYMENT: begin
                if(money>=price || Dp) next_count_clk = 12'd1;
            end
            RELEASE: begin
                if(count_clk == 12'd2000) next_count_clk = 12'd1;
                else next_count_clk = count_clk+12'd1;
            end
            CHANGE: begin
                if(money==8'd0 && count_clk==12'd2000) next_count_clk = 12'd1;
                else if(count_clk == 12'd2000) next_count_clk = 12'd1;
                else next_count_clk = count_clk+12'd1;
            end
        endcase
    end
    // next_nums
    always @* begin
        next_nums = nums;
        case(state)
            IDLE: begin
                if(Lp || Cp || Rp) next_nums = {next_person, 4'd10, next_price_BCD};
                else if(count_clk == 12'd2000) next_nums = (nums=={4{4'd10}})?{4{4'd11}}:{4{4'd10}};
            end
            TYPE: begin
                if(Up) next_nums[11:0] = {4'd10, 4'd10, next_amount};
                else if(Dp) next_nums = {4{4'd11}};
                else if(Lp || Cp || Rp) next_nums = {next_person, 4'd10, next_price_BCD};
            end
            AMOUNT: begin
                next_nums[3:0] = next_amount;
                if(Up) next_nums = {next_money_BCD, next_price_BCD};
                else if(Dp) next_nums = {4{4'd11}};
            end
            PAYMENT: begin
                next_nums[15:8] = next_money_BCD;
                if(money >= price) next_nums = {next_person, 4'd10, 4'd10, next_amount};
                else if(Dp) next_nums = {4'd10, 4'd10, next_money_BCD};
            end
            RELEASE: begin
                if(next_count_sec == 3'd5) next_nums = {4'd10, 4'd10, next_money_BCD};
            end
            CHANGE: begin
                next_nums[7:0] = next_money_BCD;
                if(money==8'd0 && count_clk==12'd2000) next_nums = {4{4'd11}};
            end
        endcase
    end
    // next_LED
    always @* begin
        next_LED = LED;
        case(state)
            IDLE: begin
                if(Lp || Cp || Rp) next_LED = 16'd0;
                else if(count_clk == 12'd2000) next_LED = LED^{16{1'b1}};
            end
            TYPE: begin
                if(Dp) next_LED = {16{1'b1}};
            end
            AMOUNT: begin
                if(Dp) next_LED = {16{1'b1}};
            end
            PAYMENT: begin
                if(money >= price) next_LED = {16{1'b1}};
            end
            RELEASE: begin
                if(next_count_sec == 3'd5) next_LED = 16'd0;
                else if(count_clk == 12'd2000) next_LED = LED^{16{1'b1}};
            end
            CHANGE: begin
                if(money==8'd0 && count_clk==12'd2000) next_LED = {16{1'b1}};
            end
        endcase
    end

endmodule

module BCD(
    input [7:0] binary,
    output reg [7:0] BCD);
    wire [7:0] b1, b2, b3, b4, b5;
    assign b1 = binary-8'd10;
    assign b2 = binary-8'd20;
    assign b3 = binary-8'd30;
    assign b4 = binary-8'd40;
    assign b5 = binary-8'd50;
    // BCD
    always @* begin
        BCD = binary;
        if(binary < 8'd10) BCD = binary;
        else if(binary < 8'd20) BCD = {4'd1, b1[3:0]};
        else if(binary < 8'd30) BCD = {4'd2, b2[3:0]};
        else if(binary < 8'd40) BCD = {4'd3, b3[3:0]};
        else if(binary < 8'd50) BCD = {4'd4, b4[3:0]};
        else if(binary < 8'd60) BCD = {4'd5, b5[3:0]};
    end
endmodule

module SevenSegment(
    output reg [6:0] display,
    output reg [3:0] digit,
    input [15:0] nums,
    input rst,
    input clk); // 100MHz
    reg [3:0] num;
    reg [15:0] clk_divider;
    // clk_divider
    always @(posedge clk, posedge rst) begin
        if(rst) clk_divider <= 16'd0;
        else clk_divider <= clk_divider+16'd1;
    end
    // num, DIGIT
    always @(posedge clk_divider[15], posedge rst) begin
        if(rst) begin
            digit <= 4'b1111;
            num <= 4'd10;
        end else begin
            case(digit)
                4'b1110: begin
                    digit <= 4'b1101;
                    num <= nums[7:4]; 
                end
                4'b1101: begin
                    digit <= 4'b1011;
                    num <= nums[11:8];
                end
                4'b1011: begin
                    digit <= 4'b0111;
                    num <= nums[15:12];
                end
                4'b0111: begin
                    digit <= 4'b1110;
                    num <= nums[3:0];
                end
                default: begin
                    digit <= 4'b1110;
                    num <= nums[3:0];
                end
            endcase
        end
    end
    // display
    always @* begin
        display = 7'b111_1111;
        case(num)
            4'd0: display = 7'b100_0000;
            4'd1: display = 7'b111_1001;
            4'd2: display = 7'b010_0100;
            4'd3: display = 7'b011_0000;
            4'd4: display = 7'b001_1001;
            4'd5: display = 7'b001_0010;
            4'd6: display = 7'b000_0010;
            4'd7: display = 7'b111_1000;
            4'd8: display = 7'b000_0000;
            4'd9: display = 7'b001_0000;
            4'd10: display = 7'b111_1111; // nothing
            4'd11: display = 7'b011_1111; // -
            4'd12: display = 7'b100_0110; // C
            4'd13: display = 7'b001_0010; // S
            4'd14: display = 7'b000_1000; // A
        endcase
    end
endmodule

module clock_divider #(parameter s=20'd25000)(
    input clk,
    output reg clk_div);
    reg [19:0] cnt, next_cnt;
    reg next_clk_div;
    // clk_div, cnt
    always @(posedge clk) begin
        clk_div <= next_clk_div;
        cnt <= next_cnt;
    end
    // next_clk_div, next_cnt
    always @* begin
        next_clk_div = clk_div;
        next_cnt = cnt+20'd1;
        if(cnt == s) begin
            next_clk_div = ~clk_div;
            next_cnt = 20'd1;
        end
    end
endmodule
