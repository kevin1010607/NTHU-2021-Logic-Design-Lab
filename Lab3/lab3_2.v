module lab3_2(
    input clk,
    input rst,
    input en,
    input dir,
    output reg [15:0] led);
    parameter FLASH = 3'b001;
    parameter SHIFT = 3'b010;
    parameter EXPAND = 3'b100;
    wire clk_div;
    reg [47:0] store, next_store;
    reg [15:0] next_led;
    reg [2:0] state, next_state, cnt, next_cnt;
    //clk_div
    clock_divider #(.n(25)) div(.clk(clk), .clk_div(clk_div));
    // led, state, cnt, store
    always @(posedge clk_div, posedge rst) begin
        if(rst == 1'b1) begin
            led <= {16{1'b1}};
            state <= FLASH;
            cnt <= 3'd0;
            store <= 48'd0;
        end
        else begin
            led <= next_led;
            state <= next_state;
            cnt <= next_cnt;
            store <= next_store;
        end
    end
    // next_state
    always @* begin
        next_state = state;
        if(en == 1'b1) begin
            case(state)
                FLASH: begin
                    if(cnt == 3'd6) next_state = SHIFT;
                end
                SHIFT: begin
                    if(led == 16'd0) next_state = EXPAND;
                end
                EXPAND: begin
                    if(led == {16{1'b1}}) next_state = FLASH;
                end
            endcase
        end
    end
    // next_led
    always @* begin
        next_led = led;
        if(en == 1'b1) begin
            case(state)
                FLASH: begin
                    if(cnt == 3'd6) next_led = {8{2'b10}};
                    else next_led = led^{16{1'b1}};
                end
                SHIFT: begin
                    if(led == 16'd0) next_led = 16'b0000_0001_1000_0000;
                    else next_led = dir?store[30:15]:store[32:17];
                end
                EXPAND: begin
                    if(led == {16{1'b1}}) next_led = 16'd0;
                    else next_led = dir?{1'b0, led[15:9], led[6:0], 1'b0}:{led[14:8], 2'b11, led[7:1]};
                end
            endcase
        end
    end
    // next_cnt
    always @* begin
        next_cnt = cnt;
        if(en == 1'b1) begin
            case(state)
                FLASH: begin
                    if(cnt == 3'd6) next_cnt = 3'd0;
                    else if(led == 16'd0) next_cnt = cnt+1'b1;
                end 
            endcase
        end
    end
    // next_store
    always @* begin
        next_store = store;
        if(en == 1'b1) begin
            case(state)
                FLASH: begin
                    if(cnt == 3'd6) next_store = {16'd0, {8{2'b10}}, 16'd0};
                end
                SHIFT: begin
                    next_store = dir?store<<1:store>>1; 
                end
            endcase
        end
    end
endmodule

module clock_divider #(parameter n=25)(
    input clk,
    output wire clk_div);
    reg [n-1:0] cnt = 0, next_cnt;
    // cnt
    always @(posedge clk) begin
        cnt <= next_cnt;
    end
    // next_cnt
    always @* begin
        next_cnt = cnt+1'b1;
    end
    // clk_div
    assign clk_div = cnt[n-1];
endmodule