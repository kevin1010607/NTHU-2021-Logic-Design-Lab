module lab7_2(
    input clk,
    input rst,
    input hold,
	inout PS2_DATA,
	inout PS2_CLK,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output pass,
    output hsync,
    output vsync
);

    wire clk_2, clk_13, clk_22;
    wire [16:0] pixel_addr;
    wire [11:0] data;
    wire [11:0] pixel;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480
    
    wire [23:0] pic;
    wire [4:0] block;
    wire [1:0] cur_dir;
    wire shift_down;
    wire hold_db;


    reg [23:0] dir, next_dir;
    
    clock_divider #(.n(2)) clk2(.clk_div(clk_2), .clk(clk));
    clock_divider #(.n(13)) clk13(.clk_div(clk_13), .clk(clk));
    clock_divider #(.n(22)) clk22(.clk_div(clk_22), .clk(clk));

    debounce holddb(.pb_debounced(hold_db), .pb(hold), .clk(clk_13));

    assign {vgaRed, vgaGreen, vgaBlue} = (valid) ? pixel : 12'h0;
    assign cur_dir = (block==4'b11_11) ? 2'b0 : {dir[(block<<1)+1], dir[block<<1]};
    assign pass = (dir==24'b0) ? 1'b1 : 1'b0;
    assign pic = (hold_db) ? 24'b0 : dir;

    always@(posedge clk, posedge rst) begin
        if(rst)
            dir <= 24'b0110_0010_1101_0010_0100_1001;
        else begin
            if(!pass)
                dir <= next_dir;
            else
                dir <= 24'b0;
        end
    end

    always@* begin
        next_dir = dir;
        if(block != 4'b11_11 && !hold_db) begin
            if(shift_down)
                {next_dir[(block<<1)+1], next_dir[block<<1]} = (cur_dir==2'b00) ? 2'b11 : cur_dir - 1'b1;
            else
                {next_dir[(block<<1)+1], next_dir[block<<1]} = (cur_dir==2'b11) ? 2'b00 : cur_dir + 1'b1;
        end
    end

	keyboard kb(
        .block(block),
        .shift_down(shift_down),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .clk(clk),
        .rst(rst)
	);

    mem_addr_gen pixeladdr(
        .pixel_addr(pixel_addr),
        .clk(clk_22),
        .rst(rst),
        .dir(pic),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .valid(valid)
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

module keyboard(
    output reg [4:0] block,
	output shift_down,
	inout PS2_DATA,
	inout PS2_CLK,
    input clk,
    input rst
);

	reg [3:0] key_num;
	
	wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;

	parameter [8:0] KEY_CODES [0:13] = {
        9'h44, //O
        9'h4D, //P
        9'h54, //{
        9'h5B, //}
        9'h42, //K
        9'h4B, //L
        9'h4C, //:
        9'h52, //"
        9'h3A, //M
        9'h41, //<
        9'h49, //>
        9'h4A, //?
		9'h59, //Rshift
		9'h12 //Lshift
    };

    assign shift_down = (key_down[KEY_CODES[12]] || key_down[KEY_CODES[13]]) ? 1'b1 : 1'b0;

	always @ (posedge clk, posedge rst) begin
		if (rst) begin
			block <= 4'b11_11;
		end
        else begin
			if (been_ready && key_down[last_change] == 1'b1) begin
				if(key_num!=4'b1111)
					block <= key_num;
			end
			else
				block <= 4'b11_11;
		end
	end

	always@* begin
		case (last_change)
			KEY_CODES[0] : key_num = 4'b00_00;
			KEY_CODES[1] : key_num = 4'b00_01;
			KEY_CODES[2] : key_num = 4'b00_10;
			KEY_CODES[3] : key_num = 4'b00_11;
			KEY_CODES[4] : key_num = 4'b01_00;
			KEY_CODES[5] : key_num = 4'b01_01;
			KEY_CODES[6] : key_num = 4'b01_10;
			KEY_CODES[7] : key_num = 4'b01_11;
			KEY_CODES[8] : key_num = 4'b10_00;
			KEY_CODES[9] : key_num = 4'b10_01;
			KEY_CODES[10] : key_num = 4'b10_10;
			KEY_CODES[11] : key_num = 4'b10_11;
			default		  : key_num = 4'b11_11;
		endcase
	end

	KeyboardDecoder key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);

endmodule

module mem_addr_gen (
    output reg [16:0] pixel_addr,
    input clk,
    input rst,
    input [23:0] dir,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input valid
);

    reg [9:0] center_x, center_y;
    reg [1:0] cur_dir;

    always@* begin
        if(v_cnt >= 0 && v_cnt < 160) begin
            if(h_cnt >= 0 && h_cnt < 160) begin
                cur_dir = dir[1:0];
                center_x = 10'd40;
                center_y = 10'd40;
            end
            else if(h_cnt >= 160 && h_cnt < 320) begin
                cur_dir = dir[3:2];
                center_x = 10'd120;
                center_y = 10'd40;
            end
            else if(h_cnt >= 320 && h_cnt < 480) begin
                cur_dir = dir[5:4];
                center_x = 10'd200;
                center_y = 10'd40;
            end
            else begin
                cur_dir = dir[7:6];
                center_x = 10'd280;
                center_y = 10'd40;
            end
        end
        else if(v_cnt >= 160 && v_cnt < 320) begin
            if(h_cnt >= 0 && h_cnt < 160) begin
                cur_dir = dir[9:8];
                center_x = 10'd40;
                center_y = 10'd120;
            end
            else if(h_cnt >= 160 && h_cnt < 320) begin
                cur_dir = dir[11:10];
                center_x = 10'd120;
                center_y = 10'd120;
            end
            else if(h_cnt >= 320 && h_cnt < 480) begin
                cur_dir = dir[13:12];
                center_x = 10'd200;
                center_y = 10'd120;
            end
            else begin
                cur_dir = dir[15:14];
                center_x = 10'd280;
                center_y = 10'd120;
            end
        end
        else begin
            if(h_cnt >= 0 && h_cnt < 160) begin
                cur_dir = dir[17:16];
                center_x = 10'd40;
                center_y = 10'd200;
            end
            else if(h_cnt >= 160 && h_cnt < 320) begin
                cur_dir = dir[19:18];
                center_x = 10'd120;
                center_y = 10'd200;
            end
            else if(h_cnt >= 320 && h_cnt < 480) begin
                cur_dir = dir[21:20];
                center_x = 10'd200;
                center_y = 10'd200;
            end
            else begin
                cur_dir = dir[23:22];
                center_x = 10'd280;
                center_y = 10'd200;
            end
        end
    end

    always@* begin
        case(cur_dir)
            2'b00:
                pixel_addr = ((h_cnt>>1) + 320*(v_cnt>>1)) % 76800; //(x, y)
            2'b01:
                pixel_addr = (((v_cnt>>1)+center_x-center_y) + 320*(center_x+center_y-(h_cnt>>1))) % 76800; // (v_cnt+x-y, x+y-h_cnt)
            2'b10:
                pixel_addr = (((center_x<<1)-(h_cnt>>1)) + 320*((center_y<<1)-(v_cnt>>1))) % 76800; // (2x-h_cnt, 2y-v_cnt)
            2'b11:
                pixel_addr = ((center_x+center_y-(v_cnt>>1)) + 320*((h_cnt>>1)-center_x+center_y)) % 76800; // (x+y-v_cnt, h_cnt-x+y)
            default:
                pixel_addr = ((h_cnt>>1) + 320*(v_cnt>>1)) % 76800;
        endcase
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

module debounce(
    output pb_debounced,
    input pb,
    input clk
);
    reg[3:0] shift_reg;
    
    always@(posedge clk) begin
        shift_reg[3:1] <= shift_reg[2:0];
        shift_reg[0] <= pb;
    end
    
    assign pb_debounced = (shift_reg ==4'b1111) ? 1'b1 : 1'b0;
endmodule