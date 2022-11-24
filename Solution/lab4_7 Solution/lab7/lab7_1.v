module lab7_1(
    input clk,
    input rst,
    input en,
    input dir,
    input nf,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
);

    wire clk_2, clk_22;
    wire [16:0] pixel_addr;
    wire [11:0] data;
    wire [11:0] pixel;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt; //480

    clock_divider #(.n(2)) clk2(.clk_div(clk_2), .clk(clk));
    clock_divider #(.n(22)) clk22(.clk_div(clk_22), .clk(clk));

    assign {vgaRed, vgaGreen, vgaBlue} = (valid) ? ((nf) ? ~pixel : pixel) : 12'h0;

    mem_addr_gen pixeladdr(
        .pixel_addr(pixel_addr),
        .clk(clk_22),
        .rst(rst),
        .en(en),
        .dir(dir),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );

    blk_mem_gen_0 blk_mem_gen_0_inst(
        .clka(clk_2),
        .wea(0),
        .addra(pixel_addr),
        .dina(data[11:0]),
        .douta(pixel)
    );

    vga_controller vga_inst(
        .pclk(clk_2),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );
endmodule

module mem_addr_gen (
    output [16:0] pixel_addr,
    input clk,
    input rst,
    input en,
    input dir,
    input [9:0] h_cnt,
    input [9:0] v_cnt
);

    reg [7:0] position;

    assign pixel_addr = ((h_cnt>>1) + 320*((v_cnt>>1)+position))% 76800;

    always@(posedge clk, posedge rst) begin
        if(rst)
            position <= 0;
        else if(en) begin
            if(dir) begin
                if(position > 0)
                    position <= position - 1;
                else
                    position <= 239;
            end
            else begin
                if(position < 239)
                    position <= position + 1;
                else
                    position <= 0;
            end
        end
    end
    
endmodule

module clock_divider(
    output clk_div,
    input clk
);
    parameter n = 26;
    reg [n-1:0] num;
    wire [n-1:0] next_num;
    
    always @(posedge clk) begin
      num <= next_num;
    end
    
    assign next_num = num + 1'b1;
    assign clk_div = num[n-1];
endmodule