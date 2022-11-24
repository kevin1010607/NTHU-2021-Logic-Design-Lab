// ex: num = 50000, freq = 100MHz/(num*2) = 1000Hz
`define S 27'd5000000 // 10Hz -> 0.1s for val
`define U 27'd50000 // 1000Hz -> refresh
`define P 27'd10000 // 5000Hz -> state, pulse
module lab4_2(
    input clk,
    input rst,
    input en,
    input input_number,
    input enter,
    input count_down,
    output wire [3:0] DIGIT,
    output wire [6:0] DISPLAY,
    output wire led0);
    wire input_number_p, enter_p, count_down_p, input_number_d, enter_d, count_down_d;
    reg [2:0] state, next_state;
    reg [3:0] val3, val2, val1, val0, next_val3, next_val2, next_val1, next_val0;
    reg [3:0] val3_t, val2_t, val1_t, val0_t, next_val3_t, next_val2_t, next_val1_t, next_val0_t;
    reg dir, next_dir, clk_now;
    wire clk_s, clk_u, clk_p;
    // state parameter
    parameter DIR_SET = 3'b000;
    parameter NUM3_SET = 3'b001;
    parameter NUM2_SET = 3'b010;
    parameter NUM1_SET = 3'b011;
    parameter NUM0_SET = 3'b100;
    parameter COUNT = 3'b101;
    // dir parameter
    parameter INC = 1'b0;
    parameter DEC = 1'b1;

    // clk
    clock_divider #(`S) cs(clk, clk_s);
    clock_divider #(`U) cu(clk, clk_u);
    clock_divider #(`P) cp(clk, clk_p);
    always @* begin
        clk_now = clk_p;
        if(state == COUNT) clk_now = clk_s;
    end
    // debounced and generate onepulse
    debounce i_d(input_number_d, input_number, clk);
    debounce e_d(enter_d, enter, clk);
    debounce c_d(count_down_d, count_down, clk);
    onepulse i_p(input_number_d, clk_p, input_number_p);
    onepulse e_p(enter_d, clk_p, enter_p);
    onepulse c_p(count_down_d, clk_p, count_down_p);
    // DIGIT, DISPLAY
    Display d(clk_u, val0, val1, val2, val3, DIGIT, DISPLAY);
    // state, dir, val3_t, val2_t, val1_t, val0_t
    always @(posedge clk_p, posedge rst) begin
        if(rst == 1'b1) begin
            state <= DIR_SET;
            dir <= INC;
            val3_t <= 4'd0;
            val2_t <= 4'd0;
            val1_t <= 4'd0;
            val0_t <= 4'd0;
        end else begin
            state <= next_state;
            dir <= next_dir;
            val3_t <= next_val3_t;
            val2_t <= next_val2_t;
            val1_t <= next_val1_t;
            val0_t <= next_val0_t;
        end
    end
    // val3, val2, val1, val0
    always @(posedge clk_now, posedge rst) begin
        if(rst == 1'b1) begin
            val3 <= 4'd10;
            val2 <= 4'd10;
            val1 <= 4'd10;
            val0 <= 4'd10;
        end else begin
            val3 <= next_val3;
            val2 <= next_val2;
            val1 <= next_val1;
            val0 <= next_val0;
        end
    end
    // next_state
    always @* begin
        next_state = state;
        case(state)
            DIR_SET: begin
                if(enter_p == 1'b1) next_state = NUM3_SET;
            end
            NUM3_SET: begin
                if(enter_p == 1'b1) next_state = NUM2_SET;
            end
            NUM2_SET: begin
                if(enter_p == 1'b1) next_state = NUM1_SET;
            end
            NUM1_SET: begin
                if(enter_p == 1'b1) next_state = NUM0_SET;
            end
            NUM0_SET: begin
                if(enter_p == 1'b1) next_state = COUNT;
            end
        endcase
    end
    // next_dir
    always @* begin
        next_dir = dir;
        if({state, count_down_p} == {DIR_SET, 1'b1}) next_dir = ~dir;
    end
    // next_val3
    always @* begin
        next_val3 = val3;
        case(state)
            DIR_SET: begin
                if(enter_p == 1'b1) next_val3 = 4'd0;
            end
            NUM3_SET: begin
                if(enter_p==1'b0 && input_number_p==1'b1) next_val3 = (val3==4'd1)?(4'd0):(val3+1'b1);
            end
            NUM0_SET: begin
                if(enter_p == 1'b1) next_val3 = dir?val3:4'd0;
            end
            COUNT: begin
                if({en, dir} == 2'b10) begin
                    if({val2, val1, val0}=={4'd5, 4'd9, 4'd9} && val3!=val3_t) next_val3 = (val3==4'd1)?(4'd0):(val3+1'b1);
                end else if({en, dir} == 2'b11) begin
                    if({val2, val1, val0}==12'd0 && val3!=4'd0) next_val3 = (val3==4'd0)?(4'd1):(val3-1'b1);
                end
            end
        endcase
    end
    // next_val2
    always @* begin
        next_val2 = val2;
        case(state)
            DIR_SET: begin
                if(enter_p == 1'b1) next_val2 = 4'd0;
            end
            NUM2_SET: begin
                if(enter_p==1'b0 && input_number_p==1'b1) next_val2 = (val2==4'd5)?(4'd0):(val2+1'b1);
            end
            NUM0_SET: begin
                if(enter_p == 1'b1) next_val2 = dir?val2:4'd0;
            end
            COUNT: begin
                if({en, dir} == 2'b10) begin
                    if({val1, val0}=={4'd9, 4'd9} && {val3, val2}!={val3_t, val2_t}) next_val2 = (val2==4'd5)?(4'd0):(val2+1'b1);
                end else if({en, dir} == 2'b11) begin
                    if({val1, val0}==8'd0 && {val3, val2}!=8'd0) next_val2 = (val2==4'd0)?(4'd5):(val2-1'b1);
                end
            end
        endcase
    end
    // next_val1
    always @* begin
        next_val1 = val1;
        case(state)
            DIR_SET: begin
                if(enter_p == 1'b1) next_val1 = 4'd0;
            end
            NUM1_SET: begin
                if(enter_p==1'b0 && input_number_p==1'b1) next_val1 = (val1==4'd9)?(4'd0):(val1+1'b1);
            end
            NUM0_SET: begin
                if(enter_p == 1'b1) next_val1 = dir?val1:4'd0;
            end
            COUNT: begin
                if({en, dir} == 2'b10) begin
                    if(val0==4'd9 && {val3, val2, val1}!={val3_t, val2_t, val1_t}) next_val1 = (val1==4'd9)?(4'd0):(val1+1'b1);
                end else if({en, dir} == 2'b11) begin
                    if(val0==4'd0 && {val3, val2, val1}!=12'd0) next_val1 = (val1==4'd0)?(4'd9):(val1-1'b1);
                end
            end
        endcase
    end
    // next_val0
    always @* begin
        next_val0 = val0;
        case(state)
            DIR_SET: begin
                if(enter_p == 1'b1) next_val0 = 4'd0;
            end
            NUM0_SET: begin
                if(enter_p == 1'b1) next_val0 = dir?val0:4'd0;
                else if(input_number_p == 1'b1) next_val0 = (val0==4'd9)?(4'd0):(val0+1'b1);
            end
            COUNT: begin
                if({en, dir} == 2'b10) begin
                    if({val3, val2, val1, val0} != {val3_t, val2_t, val1_t, val0_t}) next_val0 = (val0==4'd9)?(4'd0):(val0+1'b1);
                end else if({en, dir} == 2'b11) begin
                    if({val3, val2, val1, val0} != 16'd0) next_val0 = (val0==4'd0)?(4'd9):(val0-1'b1);
                end
            end
        endcase
    end
    // next_val3_t, next_val2_t, next_val1_t, next_val0_t
    always @* begin
        {next_val3_t, next_val2_t, next_val1_t, next_val0_t} = {val3_t, val2_t, val1_t, val0_t};
        case(state)
            NUM3_SET: next_val3_t = val3;
            NUM2_SET: next_val2_t = val2;
            NUM1_SET: next_val1_t = val1;
            NUM0_SET: next_val0_t = val0;
        endcase
    end
    // led0
    assign led0 = dir;
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
            4'd10: DISPLAY = 7'b011_1111;
        endcase
    end
endmodule

module clock_divider #(parameter s=`U)(
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