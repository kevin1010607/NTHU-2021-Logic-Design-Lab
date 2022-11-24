module lab7_1(
    input clk,
    input rst,
    input en,
    input dir,
    input nf,
    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue,
    output wire hsync,
    output wire vsync
    );
    wire [16:0] pixel_addr;
    wire [11:0] data, pixel;
    wire [9:0] h_cnt, v_cnt;
    wire clk_2, clk_22, valid;
    
    // vgaRed, vgaGreen, vgaBlue
    always @* begin
        if(valid) {vgaRed, vgaGreen, vgaBlue} = (nf)?(pixel^12'hfff):(pixel);
        else {vgaRed, vgaGreen, vgaBlue} = 12'd0;
    end

    clock_divider c(
        .clk(clk),
        .clk_2(clk_2),
        .clk_22(clk_22)
    );
    mem_addr_gen m(
        .clk(clk_22),
        .rst(rst),
        .en(en),
        .dir(dir),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .pixel_addr(pixel_addr)
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
endmodule

module mem_addr_gen(
        input clk,
        input rst,
        input en,
        input dir,
        input [9:0] h_cnt,
        input [9:0] v_cnt,
        output wire [16:0] pixel_addr
    );
    reg [7:0] pos, next_pos;
    // pixel_addr
    assign pixel_addr = ((h_cnt>>1)+320*(v_cnt>>1)+320*(pos))%76800;    
    // pos
    always @(posedge clk, posedge rst) begin
        if(rst) pos <= 8'd0;
        else pos <= next_pos;
    end
    // next_pos
    always @* begin
        next_pos = pos;
        if(en) begin
            if(dir) next_pos = (pos==8'd0)?(8'd239):(pos-8'd1);
            else next_pos = (pos==8'd239)?(8'd0):(pos+8'd1);
        end
    end
endmodule

module clock_divider(
    input clk,
    output wire clk_2,
    output wire clk_22
    );
    reg [21:0] cnt, next_cnt;
    // cnt
    always @(posedge clk) begin
        cnt <= next_cnt;
    end
    // next_cnt
    always @* begin
        next_cnt = cnt+22'd1;
    end
    // clk_2, clk_22
    assign clk_2 = cnt[1];
    assign clk_22 = cnt[21];
endmodule