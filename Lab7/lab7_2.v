module lab7_2(
    input clk,
    input rst,
    input hold,
    inout PS2_CLK,
    inout PS2_DATA,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire hsync,
    output wire vsync,
    output wire pass
    );
    // vga
    wire [16:0] pixel_addr;
    wire [11:0] data, pixel;
    wire [9:0] h_cnt, v_cnt;
    wire valid;
    // keyboard
    wire [511:0] key_down;
    wire [8:0] last_change;
    wire been_ready;
    // clk
    wire clk_2;

    assign {vgaRed, vgaGreen, vgaBlue} = (valid)?(pixel):(12'd0);

    clock_divider c(
        .clk(clk),
        .clk_2(clk_2)
    );
    mem_addr_gen m(
        .clk(clk_2),
        .rst(rst),
        .hold(hold),
        .key_down(key_down),
        .last_change(last_change),
        .been_ready(been_ready),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr(pixel_addr),
        .pass(pass)
    );
    blk_mem_gen_0 b(
        .clka(clk_2),
        .wea(0),
        .addra(pixel_addr),
        .dina(data[11:0]),
        .douta(pixel)
    );
    vga_controller v(
        .pclk(clk_2),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );
    KeyboardDecoder k(
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(been_ready),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk_2)
    );
endmodule

module mem_addr_gen(
    input clk,
    input rst,
    input hold,
    input [511:0] key_down,
    input [8:0] last_change,
    input been_ready,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    output reg [16:0] pixel_addr,
    output wire pass
    );
    // parameter for pos
    parameter [3:0] NULL = 4'd12;
    // parameter for key codes
    parameter [8:0] LEFT_SHIFT_CODES = 9'b0_0001_0010;
    parameter [8:0] RIGHT_SHIFT_CODES = 9'b0_0101_1001;
    parameter [8:0] KEY_CODES [0:11] = {
        9'b0_0100_0100, // O => 44
        9'b0_0100_1101, // P => 4D
        9'b0_0101_0100, // [ => 54
        9'b0_0101_1011, // ] => 5B
        9'b0_0100_0010, // K => 42
        9'b0_0100_1011, // L => 4B
        9'b0_0100_1100, // ; => 4C
        9'b0_0101_0010, // ' => 52
        9'b0_0011_1010, // M => 3A
        9'b0_0100_0001, // , => 41
        9'b0_0100_1001, // . => 49
        9'b0_0100_1010 // / => 4A
    };
    
    reg [1:0] state [0:11], next_state [0:11];
    reg [16:0] next_pixel_addr;
    reg [9:0] L, U;
    reg [3:0] pos;
    integer i;

    // state, pixel_addr
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            {state[0], state[5], state[10], state[8]} <= {4{2'd1}};
            {state[4], state[1], state[6], state[11]} <= {4{2'd2}};
            {state[3], state[9], state[2], state[7]} <= {4{2'd3}};
            pixel_addr <= 17'd0;
        end else begin
            for(i = 0; i < 12; i = i+1) state[i] <= next_state[i];
            pixel_addr <= next_pixel_addr;
        end
    end
    // pass
    assign pass = {state[0], state[1], state[2], state[3], state[4], state[5], 
        state[6], state[7], state[8], state[9], state[10], state[11]}==24'd0;
    // pos, L, U
    always @* begin
        pos = NULL;
        L = 10'd0;
        U = 10'd0;
        if(v_cnt < 10'd160) begin
            U = 10'd0;
            if(h_cnt < 10'd160) begin
                pos = 4'd0;
                L = 10'd0;
            end else if(h_cnt < 10'd320) begin
                pos = 4'd1;
                L = 10'd160;
            end else if(h_cnt < 10'd480) begin
                pos = 4'd2;
                L = 10'd320;
            end else if(h_cnt < 10'd640) begin
                pos = 4'd3;
                L = 10'd480;
            end
        end else if(v_cnt < 10'd320) begin
            U = 10'd160;
            if(h_cnt < 10'd160) begin
                pos = 4'd4;
                L = 10'd0;
            end else if(h_cnt < 10'd320) begin
                pos = 4'd5;
                L = 10'd160;
            end else if(h_cnt < 10'd480) begin
                pos = 4'd6;
                L = 10'd320;
            end else if(h_cnt < 10'd640) begin
                pos = 4'd7;
                L = 10'd480;
            end
        end else if(v_cnt < 10'd480) begin   
            U = 10'd320;
            if(h_cnt < 10'd160) begin
                pos = 4'd8;
                L = 10'd0;
            end else if(h_cnt < 10'd320) begin
                pos = 4'd9;
                L = 10'd160;
            end else if(h_cnt < 10'd480) begin
                pos = 4'd10;
                L = 10'd320;
            end else if(h_cnt < 10'd640) begin
                pos = 4'd11;
                L = 10'd480;
            end
        end
    end
    // next_state
    always @* begin
        for(i = 0; i < 12; i = i+1) begin
            next_state[i] = state[i];
            if(!pass && !hold && been_ready && key_down[last_change]) begin
                if(last_change == KEY_CODES[i]) begin
                    if(key_down[LEFT_SHIFT_CODES] || key_down[RIGHT_SHIFT_CODES]) next_state[i] = state[i]-2'd1;
                    else next_state[i] = state[i]+2'd1;
                end
            end
        end
    end
    // next_pixel_addr
    always @* begin
        next_pixel_addr = 17'd0;
        if(hold) begin
            next_pixel_addr = (h_cnt>>1)+320*(v_cnt>>1);
        end else if(pos < NULL) begin
            case(state[pos])
                2'd0: next_pixel_addr = (h_cnt>>1)+320*(v_cnt>>1);
                2'd1: next_pixel_addr = ((L+(v_cnt-U))>>1)+320*((U+(L+10'd160-h_cnt))>>1);
                2'd2: next_pixel_addr = ((L+(L+10'd160-h_cnt))>>1)+320*((U+(U+10'd160-v_cnt))>>1);
                2'd3: next_pixel_addr = ((L+(U+10'd160-v_cnt))>>1)+320*((U+(h_cnt-L))>>1);
            endcase
        end
    end
endmodule

module clock_divider(
    input clk,
    output wire clk_2
    );
    reg [1:0] cnt, next_cnt;
    // cnt
    always @(posedge clk) begin
        cnt <= next_cnt;
    end
    // next_cnt
    always @* begin
        next_cnt = cnt+2'd1;
    end
    // clk_2
    assign clk_2 = cnt[1];
endmodule