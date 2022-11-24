`define _G2  32'd98
`define bA2	 32'd104
`define bB2  32'd117

`define _C3  32'd113 // slow Do
`define _D3  32'd147
`define bE3  32'd156
`define _E3  32'd165
`define _F3  32'd174
`define _G3  32'd196
`define bA3  32'd208
`define _A3  32'd220
`define bB3  32'd233
`define _B3  32'd247

`define _C4  32'd262 // Do
`define sC4	 32'd277
`define bD4  32'd277
`define _D4  32'd294
`define sD4  32'd311
`define bE4  32'd311
`define _E4  32'd330
`define _F4  32'd349
`define sF4	 32'd370
`define bG4  32'd370
`define _G4  32'd392
`define sG4	 32'd415
`define bA4  32'd415
`define _A4  32'd440
`define sA4  32'd466
`define bB4  32'd466
`define _B4  32'd494

`define _C5  32'd523 // high Do
`define _D5  32'd587
`define bE5	 32'd622
`define _E5  32'd659
`define _F5  32'd698
`define _G5  32'd784
`define _A5  32'd880
`define _B5  32'd988

`define sil 32'd50000000

module lab8(
    clk,        // clock from crystal
    rst,        // BTNC: active high reset
    _play,      // SW0: Play/Pause
    _mute,      // SW1: Mute
    _slow,      // SW2: Slow
    _music,     // SW3: Music
    _mode,      // SW15: Mode
    _volUP,     // BTNU: Vol up
    _volDOWN,   // BTND: Vol down
    _higherOCT, // BTNR: Oct higher
    _lowerOCT,  // BTNL: Oct lower
    PS2_DATA,   // Keyboard I/O
    PS2_CLK,    // Keyboard I/O
    _led,       // LED: [15:13] octave & [4:0] volume
    audio_mclk, // master clock
    audio_lrck, // left-right clock
    audio_sck,  // serial clock
    audio_sdin, // serial audio data input
    DISPLAY,    // 7-seg
    DIGIT       // 7-seg
    );

    // I/O declaration
    input clk; 
    input rst; 
    input _play, _mute, _slow, _music, _mode; 
    input _volUP, _volDOWN, _higherOCT, _lowerOCT; 
    inout PS2_DATA; 
	inout PS2_CLK; 
    output reg [15:0] _led; 
    output audio_mclk; 
    output audio_lrck; 
    output audio_sck; 
    output audio_sdin; 
    output [6:0] DISPLAY; 
    output [3:0] DIGIT;

    // Debounce and Onepulse
    wire vud, vdd, hod, lod, vup, vdp, hop, lop;

    // Internal Signal
    wire [2:0] volume;
    wire [1:0] rct;
    wire [15:0] audio_in_left, audio_in_right;
    wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3

    // Debounce and Onepulse
    debounce d1(
        .pb_debounced(vud),
        .pb(_volUP),
        .clk(clk)
    );
    debounce d2(
        .pb_debounced(vdd),
        .pb(_volDOWN),
        .clk(clk)
    );
    debounce d3(
        .pb_debounced(hod),
        .pb(_higherOCT),
        .clk(clk)
    );
    debounce d4(
        .pb_debounced(lod),
        .pb(_lowerOCT),
        .clk(clk)
    );

    onepulse o1(
        .signal(vud),
        .clk(clk),
        .op(vup)
    );
    onepulse o2(
        .signal(vdd),
        .clk(clk),
        .op(vdp)
    );
    onepulse o3(
        .signal(hod),
        .clk(clk),
        .op(hop)
    );
    onepulse o4(
        .signal(lod),
        .clk(clk),
        .op(lop)
    );

    // _led
    always @* begin
        _led = 16'd0;
        case(rct)
            2'd1: _led[15] = 1'b1;
            2'd2: _led[14] = 1'b1;
            2'd3: _led[13] = 1'b1;
        endcase
        case(volume)
            3'd1: _led[0] = 1'b1;
            3'd2: _led[1:0] = 2'b11;
            3'd3: _led[2:0] = 3'b111;
            3'd4: _led[3:0] = 4'b1111;
            3'd5: _led[4:0] = 5'b11111;
        endcase
    end

    // freqL, freqR, DISPLAY, DIGIT, RCT
    freq_gen f(
        .clk(clk),
        .rst(rst),
        .play(_play),
        .slow(_slow),
        .music(_music),
        .mode(_mode),
        .higherOCT(hop),
        .lowerOCT(lop),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .freqL(freqL),
        .freqR(freqR),
        .DISPLAY(DISPLAY),
        .DIGIT(DIGIT),
        .rct(rct)
    );

    // volumn
    vol_gen v(
        .clk(clk),
        .rst(rst),
        .mute(_mute),
        .volUP(vup),
        .volDOWN(vdp),
        .volume(volume)
    );

    // freq_outL, freq_outR
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    assign freq_outL = 50000000 / freqL;
    assign freq_outR = 50000000 / freqR;

    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        .clk(clk), 
        .rst(rst), 
        .volume(volume),
        .note_div_left(freq_outL), 
        .note_div_right(freq_outR), 
        .audio_left(audio_in_left),     // left sound audio
        .audio_right(audio_in_right)    // right sound audio
    );

    // Speaker controller
    speaker_control sc(
        .clk(clk), 
        .rst(rst), 
        .audio_in_left(audio_in_left),      // left channel audio data input
        .audio_in_right(audio_in_right),    // right channel audio data input
        .audio_mclk(audio_mclk),            // master clock
        .audio_lrck(audio_lrck),            // left-right clock
        .audio_sck(audio_sck),              // serial clock
        .audio_sdin(audio_sdin)             // serial audio data input
    );

endmodule

module note_gen(
    clk, // clock from crystal
    rst, // active high reset
    volume, 
    note_div_left, // div for note generation
    note_div_right,
    audio_left,
    audio_right
    );

    // I/O declaration
    input clk; // clock from crystal
    input rst; // active low reset
    input [2:0] volume;
    input [21:0] note_div_left, note_div_right; // div for note generation
    output reg [15:0] audio_left, audio_right;

    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;

    // Note frequency generation
    // clk_cnt, clk_cnt_2, b_clk, c_clk
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
    
    // clk_cnt_next, b_clk_next
    always @*
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    // clk_cnt_next_2, c_clk_next
    always @*
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end

    // Assign the amplitude of the note
    // Volume is controlled here

    // audio_left
    always @* begin
        audio_left = 16'h0000;
        if(note_div_left != 22'd1) begin
            case(volume)
                3'd1: audio_left = (b_clk == 1'b0)?16'hE000:16'h2000;
                3'd2: audio_left = (b_clk == 1'b0)?16'hD000:16'h3000;
                3'd3: audio_left = (b_clk == 1'b0)?16'hC000:16'h4000;
                3'd4: audio_left = (b_clk == 1'b0)?16'hB000:16'h5000;
                3'd5: audio_left = (b_clk == 1'b0)?16'hA000:16'h6000;
            endcase    
        end
    end

    // audio_right
    always @* begin
        audio_right = 16'h0000;
        if(note_div_right != 22'd1) begin
            case(volume)
                3'd1: audio_right = (b_clk == 1'b0)?16'hE000:16'h2000;
                3'd2: audio_right = (b_clk == 1'b0)?16'hD000:16'h3000;
                3'd3: audio_right = (b_clk == 1'b0)?16'hC000:16'h4000;
                3'd4: audio_right = (b_clk == 1'b0)?16'hB000:16'h5000;
                3'd5: audio_right = (b_clk == 1'b0)?16'hA000:16'h6000;
            endcase    
        end
    end
    // assign audio_left = (note_div_left == 22'd1) ? 16'h0000 : 
    //                             (b_clk == 1'b0) ? 16'hE000 : 16'h2000;
    // assign audio_right = (note_div_right == 22'd1) ? 16'h0000 : 
    //                             (c_clk == 1'b0) ? 16'hE000 : 16'h2000;
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
    		0 : display = 7'b1000110;	// C
			1 : display = 7'b1000000;   // D                                         
			2 : display = 7'b0000110;   // E                                            
			3 : display = 7'b0001110;   // F                                        
			4 : display = 7'b1000010;   // G
			5 : display = 7'b0001000;   // A
			6 : display = 7'b0000000;   // B
			7 : display = 7'b0011100;   // #
			8 : display = 7'b0000011;   // b
			9 : display = 7'b0111111;	// -
			default : display = 7'b1111111;
    	endcase
    end
    
endmodule

module clock_divider(clk, clk_div);   
    parameter n = 26;     
    input clk;   
    output clk_div;   
    
    reg [n-1:0] num;
    wire [n-1:0] next_num;
    
    always@(posedge clk)begin
    	num<=next_num;
    end
    
    assign next_num = num +1;
    assign clk_div = num[n-1];
    
endmodule

module freq_gen(
    input clk,
    input rst,
    input play,
    input slow,
    input music,
    input mode,
    input higherOCT,
    input lowerOCT,
    input PS2_DATA,
    input PS2_CLK,
    output reg [31:0] freqL,
    output reg [31:0] freqR,
    output wire [6:0] DISPLAY,
    output wire [3:0] DIGIT,
    output reg [1:0] rct
	);
    parameter KEY_CODE_A = 9'b0_0001_1100; // A => 1C
    parameter KEY_CODE_S = 9'b0_0001_1011; // S => 1B
    parameter KEY_CODE_D = 9'b0_0010_0011; // D => 23
    parameter KEY_CODE_F = 9'b0_0010_1011; // F => 2B
    parameter KEY_CODE_G = 9'b0_0011_0100; // G => 34
    parameter KEY_CODE_H = 9'b0_0011_0011; // H => 33
    parameter KEY_CODE_J = 9'b0_0011_1011; // J => 3B

    reg state, next_state;
	reg [1:0] next_rct;

	reg song, next_song, cnt, next_cnt;
    reg [8:0] beat, next_beat;
    reg [31:0] next_freqL, next_freqR;
	reg [15:0] nums, next_nums;

	reg [7:0] pitch;
    
    wire clk_div;
    wire [31:0] demo_freqL, demo_freqR, demo1_freqL, demo2_freqL, demo1_freqR, demo2_freqR;

    wire [511:0] key_down;
    wire [8:0] last_change;
    wire been_ready;

	// demo_freqL, demo_freqR
	assign demo_freqL = music?demo1_freqL:demo2_freqL;
	assign demo_freqR = music?demo1_freqR:demo2_freqR;

    // state, rct
    always @(posedge clk, posedge rst) begin
        if(rst) begin
            state <= mode;
            rct <= 2'd2;
        end else begin
            state <= next_state;
            rct <= next_rct;
        end
    end
    // song, cnt, beat, freqL, freqR, nums
    always @(posedge clk_div, posedge rst) begin
        if(rst) begin
			song <= music;
            cnt <= 1'b0;
            beat <= 9'd0;
            freqL <= `sil;
            freqR <= `sil;
            nums <= {4{4'd9}};
        end else begin
			song <= next_song;
            cnt <= next_cnt;
            beat <= next_beat;
            freqL <= next_freqL;
            freqR <= next_freqR;
            nums <= next_nums;
        end
    end

    // next_state
    always @* begin
        next_state = mode;
    end
    // next_rct
    always @* begin
        next_rct = rct;
        if(higherOCT && rct!=2'd3) next_rct = rct+2'd1;
        else if(lowerOCT && rct!=2'd1) next_rct = rct-2'd1;
    end
	// next_song
	always @* begin
		next_song = music;
	end
    // next_cnt
    always @* begin
        next_cnt = cnt+1'b1;
    end
    // next_beat
    always @* begin
        next_beat = beat;
        if(state && play) begin
			if(song != next_song) next_beat = 9'd0;
            else if(!slow) next_beat = beat+9'd1;
            else if(cnt) next_beat = beat+9'd1;
        end
    end

    // next_freqL, next_freqR, pitch
    always @* begin
        next_freqL = `sil;
        next_freqR = `sil;
		pitch = {2{4'd9}};
        case(state)
            1'b0: begin
                if(key_down[KEY_CODE_A]) begin
                    next_freqL = (rct==2'd2)?(`_C4):((rct==2'd1)?(`_C3):(`_C5));
                    next_freqR = (rct==2'd2)?(`_C4):((rct==2'd1)?(`_C3):(`_C5));
					pitch = {4'd9, 4'd0};
                end else if(key_down[KEY_CODE_S]) begin
                    next_freqL = (rct==2'd2)?(`_D4):((rct==2'd1)?(`_D3):(`_D5));
                    next_freqR = (rct==2'd2)?(`_D4):((rct==2'd1)?(`_D3):(`_D5));
					pitch = {4'd9, 4'd1};
                end else if(key_down[KEY_CODE_D]) begin
                    next_freqL = (rct==2'd2)?(`_E4):((rct==2'd1)?(`_E3):(`_E5));
                    next_freqR = (rct==2'd2)?(`_E4):((rct==2'd1)?(`_E3):(`_E5));
					pitch = {4'd9, 4'd2};
                end else if(key_down[KEY_CODE_F]) begin
                    next_freqL = (rct==2'd2)?(`_F4):((rct==2'd1)?(`_F3):(`_F5));
                    next_freqR = (rct==2'd2)?(`_F4):((rct==2'd1)?(`_F3):(`_F5));
					pitch = {4'd9, 4'd3};
                end else if(key_down[KEY_CODE_G]) begin
                    next_freqL = (rct==2'd2)?(`_G4):((rct==2'd1)?(`_G3):(`_G5));
                    next_freqR = (rct==2'd2)?(`_G4):((rct==2'd1)?(`_G3):(`_G5));
					pitch = {4'd9, 4'd4};
                end else if(key_down[KEY_CODE_H]) begin
                    next_freqL = (rct==2'd2)?(`_A4):((rct==2'd1)?(`_A3):(`_A5));
                    next_freqR = (rct==2'd2)?(`_A4):((rct==2'd1)?(`_A3):(`_A5));
					pitch = {4'd9, 4'd5};
                end else if(key_down[KEY_CODE_J]) begin
                    next_freqL = (rct==2'd2)?(`_B4):((rct==2'd1)?(`_B3):(`_B5));
                    next_freqR = (rct==2'd2)?(`_B4):((rct==2'd1)?(`_B3):(`_B5));
					pitch = {4'd9, 4'd6};
                end
            end
            1'b1: begin
				if(play) begin
                	next_freqL = (rct==2'd2)?(demo_freqL):((rct==2'd1)?(demo_freqL>>1):(demo_freqL<<1));
                	next_freqR = (rct==2'd2)?(demo_freqR):((rct==2'd1)?(demo_freqR>>1):(demo_freqR<<1));
					if(demo_freqL==`_C3||demo_freqL==`_C4||demo_freqL==`_C5) pitch = {4'd9, 4'd0};
					else if(demo_freqL==`_D3||demo_freqL==`_D4||demo_freqL==`_D5) pitch = {4'd9, 4'd1};
					else if(demo_freqL==`_E3||demo_freqL==`_E4||demo_freqL==`_E5) pitch = {4'd9, 4'd2};
					else if(demo_freqL==`_F3||demo_freqL==`_F4||demo_freqL==`_F5) pitch = {4'd9, 4'd3};
					else if(demo_freqL==`_G2||demo_freqL==`_G3||demo_freqL==`_G4||demo_freqL==`_G5) pitch = {4'd9, 4'd4};
					else if(demo_freqL==`_A3||demo_freqL==`_A4||demo_freqL==`_A5) pitch = {4'd9, 4'd5};
					else if(demo_freqL==`_B3||demo_freqL==`_B4||demo_freqL==`_B5) pitch = {4'd9, 4'd6};
					else if(demo_freqL==`bD4) pitch = {4'd8, 4'd1};
					else if(demo_freqL==`sC4) pitch = {4'd7, 4'd0};
					else if(demo_freqL==`bE3||demo_freqL==`bE4||demo_freqL==`bE5) pitch = {4'd8, 4'd2};
					else if(demo_freqL==`sD4) pitch = {4'd7, 4'd1};
					else if(demo_freqL==`bG4) pitch = {4'd8, 4'd4};
					else if(demo_freqL==`sF4) pitch = {4'd7, 4'd3};
					else if(demo_freqL==`bA2||demo_freqL==`bA3||demo_freqL==`bA4) pitch = {4'd8, 4'd5};
					else if(demo_freqL==`sG4) pitch = {4'd7, 4'd4};
					else if(demo_freqL==`bB2||demo_freqL==`bB3||demo_freqL==`bB4) pitch = {4'd8, 4'd6};
					else if(demo_freqL==`sA4) pitch = {4'd7, 4'd5};
				end
            end
        endcase
    end

	// next_nums
	always @* begin
		next_nums = {{2{4'd9}}, pitch};
	end

    // music1
    music1 m1(
        .beat(beat),
        .freqL(demo1_freqL),
        .freqR(demo1_freqR)
    );
	//music2
	music2 m2(
        .beat(beat),
        .freqL(demo2_freqL),
        .freqR(demo2_freqR)
    );

    // clock_divider
    clock_divider #(.n(22)) c(
        .clk(clk),
        .clk_div(clk_div)
    );

    // KeyboardDecoder
    KeyboardDecoder kd(
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(been_ready),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );
	
    // SevenSegment
    SevenSegment ss(
        .display(DISPLAY),
        .digit(DIGIT),
        .nums(nums),
        .clk(clk)
    );

endmodule

module music1(
    input [8:0] beat,
    output reg [31:0] freqL,
    output reg [31:0] freqR
    );

    // freqL
	always @* begin
		case(beat)
			// --- Measure 1 ---
			9'd0: freqL = `_E5;		9'd1: freqL = `_E5;
			9'd2: freqL = `_E5;		9'd3: freqL = `_E5;
			9'd4: freqL = `_E5;		9'd5: freqL = `_E5;
			9'd6: freqL = `_E5;		9'd7: freqL = `sil;
			9'd8: freqL = `_E5;		9'd9: freqL = `_E5;
			9'd10: freqL = `_E5;		9'd11: freqL = `_E5;
			9'd12: freqL = `_E5;		9'd13: freqL = `_E5;
			9'd14: freqL = `_E5;		9'd15: freqL = `sil;
			9'd16: freqL = `_E5;		9'd17: freqL = `_E5;
			9'd18: freqL = `_E5;		9'd19: freqL = `_E5;
			9'd20: freqL = `_E5;		9'd21: freqL = `_E5;
			9'd22: freqL = `_E5;		9'd23: freqL = `_E5;
			9'd24: freqL = `_E5;		9'd25: freqL = `_E5;
			9'd26: freqL = `_E5;		9'd27: freqL = `_E5;
			9'd28: freqL = `_E5;		9'd29: freqL = `_E5;
			9'd30: freqL = `_E5;		9'd31: freqL = `sil;
			9'd32: freqL = `_E5;		9'd33: freqL = `_E5;
			9'd34: freqL = `_E5;		9'd35: freqL = `_E5;
			9'd36: freqL = `_E5;		9'd37: freqL = `_E5;
			9'd38: freqL = `_E5;		9'd39: freqL = `sil;
			9'd40: freqL = `_E5;		9'd41: freqL = `_E5;
			9'd42: freqL = `_E5;		9'd43: freqL = `_E5;
			9'd44: freqL = `_E5;		9'd45: freqL = `_E5;
			9'd46: freqL = `_E5;		9'd47: freqL = `sil;
			9'd48: freqL = `_E5;		9'd49: freqL = `_E5;
			9'd50: freqL = `_E5;		9'd51: freqL = `_E5;
			9'd52: freqL = `_E5;		9'd53: freqL = `_E5;
			9'd54: freqL = `_E5;		9'd55: freqL = `_E5;
			9'd56: freqL = `_E5;		9'd57: freqL = `_E5;
			9'd58: freqL = `_E5;		9'd59: freqL = `_E5;
			9'd60: freqL = `_E5;		9'd61: freqL = `_E5;
			9'd62: freqL = `_E5;		9'd63: freqL = `sil;
			// --- Measure 2 ---
			9'd64: freqL = `_E5;		9'd65: freqL = `_E5;
			9'd66: freqL = `_E5;		9'd67: freqL = `_E5;
			9'd68: freqL = `_E5;		9'd69: freqL = `_E5;
			9'd70: freqL = `_E5;		9'd71: freqL = `_E5;
			9'd72: freqL = `_G5;		9'd73: freqL = `_G5;
			9'd74: freqL = `_G5;		9'd75: freqL = `_G5;
			9'd76: freqL = `_G5;		9'd77: freqL = `_G5;
			9'd78: freqL = `_G5;		9'd79: freqL = `_G5;
			9'd80: freqL = `_C5;		9'd81: freqL = `_C5;
			9'd82: freqL = `_C5;		9'd83: freqL = `_C5;
			9'd84: freqL = `_C5;		9'd85: freqL = `_C5;
			9'd86: freqL = `_C5;		9'd87: freqL = `_C5;
			9'd88: freqL = `_D5;		9'd89: freqL = `_D5;
			9'd90: freqL = `_D5;		9'd91: freqL = `_D5;
			9'd92: freqL = `_D5;		9'd93: freqL = `_D5;
			9'd94: freqL = `_D5;		9'd95: freqL = `_D5;
			9'd96: freqL = `_E5;		9'd97: freqL = `_E5;
			9'd98: freqL = `_E5;		9'd99: freqL = `_E5;
			9'd100: freqL = `_E5;		9'd101: freqL = `_E5;
			9'd102: freqL = `_E5;		9'd103: freqL = `_E5;
			9'd104: freqL = `_E5;		9'd105: freqL = `_E5;
			9'd106: freqL = `_E5;		9'd107: freqL = `_E5;
			9'd108: freqL = `_E5;		9'd109: freqL = `_E5;
			9'd110: freqL = `_E5;		9'd111: freqL = `_E5;
			9'd112: freqL = `_E5;		9'd113: freqL = `_E5;
			9'd114: freqL = `_E5;		9'd115: freqL = `_E5;
			9'd116: freqL = `_E5;		9'd117: freqL = `_E5;
			9'd118: freqL = `_E5;		9'd119: freqL = `_E5;
			9'd120: freqL = `_E5;		9'd121: freqL = `_E5;
			9'd122: freqL = `_E5;		9'd123: freqL = `_E5;
			9'd124: freqL = `_E5;		9'd125: freqL = `_E5;
			9'd126: freqL = `_E5;		9'd127: freqL = `_E5;
			// --- Measure 3 ---
			9'd128: freqL = `_F5;		9'd129: freqL = `_F5;
			9'd130: freqL = `_F5;		9'd131: freqL = `_F5;
			9'd132: freqL = `_F5;		9'd133: freqL = `_F5;
			9'd134: freqL = `_F5;		9'd135: freqL = `sil;
			9'd136: freqL = `_F5;		9'd137: freqL = `_F5;
			9'd138: freqL = `_F5;		9'd139: freqL = `_F5;
			9'd140: freqL = `_F5;		9'd141: freqL = `_F5;
			9'd142: freqL = `_F5;		9'd143: freqL = `sil;
			9'd144: freqL = `_F5;		9'd145: freqL = `_F5;
			9'd146: freqL = `_F5;		9'd147: freqL = `_F5;
			9'd148: freqL = `_F5;		9'd149: freqL = `_F5;
			9'd150: freqL = `_F5;		9'd151: freqL = `_F5;
			9'd152: freqL = `_F5;		9'd153: freqL = `_F5;
			9'd154: freqL = `_F5;		9'd155: freqL = `sil;
			9'd156: freqL = `_F5;		9'd157: freqL = `_F5;
			9'd158: freqL = `_F5;		9'd159: freqL = `sil;
			9'd160: freqL = `_F5;		9'd161: freqL = `_F5;
			9'd162: freqL = `_F5;		9'd163: freqL = `_F5;
			9'd164: freqL = `_F5;		9'd165: freqL = `_F5;
			9'd166: freqL = `_F5;		9'd167: freqL = `_F5;
			9'd168: freqL = `_E5;		9'd169: freqL = `_E5;
			9'd170: freqL = `_E5;		9'd171: freqL = `_E5;
			9'd172: freqL = `_E5;		9'd173: freqL = `_E5;
			9'd174: freqL = `_E5;		9'd175: freqL = `sil;
			9'd176: freqL = `_E5;		9'd177: freqL = `_E5;
			9'd178: freqL = `_E5;		9'd179: freqL = `_E5;
			9'd180: freqL = `_E5;		9'd181: freqL = `_E5;
			9'd182: freqL = `_E5;		9'd183: freqL = `_E5;
			9'd184: freqL = `_E5;		9'd185: freqL = `_E5;
			9'd186: freqL = `_E5;		9'd187: freqL = `sil;
			9'd188: freqL = `_E5;		9'd189: freqL = `_E5;
			9'd190: freqL = `_E5;		9'd191: freqL = `sil;
			// --- Measure 4 ---
			9'd192: freqL = `_E5;		9'd193: freqL = `_E5;
			9'd194: freqL = `_E5;		9'd195: freqL = `_E5;
			9'd196: freqL = `_E5;		9'd197: freqL = `_E5;
			9'd198: freqL = `_E5;		9'd199: freqL = `_E5;
			9'd200: freqL = `_D5;		9'd201: freqL = `_D5;
			9'd202: freqL = `_D5;		9'd203: freqL = `_D5;
			9'd204: freqL = `_D5;		9'd205: freqL = `_D5;
			9'd206: freqL = `_D5;		9'd207: freqL = `sil;
			9'd208: freqL = `_D5;		9'd209: freqL = `_D5;
			9'd210: freqL = `_D5;		9'd211: freqL = `_D5;
			9'd212: freqL = `_D5;		9'd213: freqL = `_D5;
			9'd214: freqL = `_D5;		9'd215: freqL = `_D5;
			9'd216: freqL = `_E5;		9'd217: freqL = `_E5;
			9'd218: freqL = `_E5;		9'd219: freqL = `_E5;
			9'd220: freqL = `_E5;		9'd221: freqL = `_E5;
			9'd222: freqL = `_E5;		9'd223: freqL = `_E5;
			9'd224: freqL = `_D5;		9'd225: freqL = `_D5;
			9'd226: freqL = `_D5;		9'd227: freqL = `_D5;
			9'd228: freqL = `_D5;		9'd229: freqL = `_D5;
			9'd230: freqL = `_D5;		9'd231: freqL = `_D5;
			9'd232: freqL = `_D5;		9'd233: freqL = `_D5;
			9'd234: freqL = `_D5;		9'd235: freqL = `_D5;
			9'd236: freqL = `_D5;		9'd237: freqL = `_D5;
			9'd238: freqL = `_D5;		9'd239: freqL = `_D5;
			9'd240: freqL = `_G5;		9'd241: freqL = `_G5;
			9'd242: freqL = `_G5;		9'd243: freqL = `_G5;
			9'd244: freqL = `_G5;		9'd245: freqL = `_G5;
			9'd246: freqL = `_G5;		9'd247: freqL = `_G5;
			9'd248: freqL = `_G5;		9'd249: freqL = `_G5;
			9'd250: freqL = `_G5;		9'd251: freqL = `_G5;
			9'd252: freqL = `_G5;		9'd253: freqL = `_G5;
			9'd254: freqL = `_G5;		9'd255: freqL = `_G5;
			// --- Measure 5 ---
			9'd256: freqL = `_E5;		9'd257: freqL = `_E5;
			9'd258: freqL = `_E5;		9'd259: freqL = `_E5;
			9'd260: freqL = `_E5;		9'd261: freqL = `_E5;
			9'd262: freqL = `_E5;		9'd263: freqL = `sil;
			9'd264: freqL = `_E5;		9'd265: freqL = `_E5;
			9'd266: freqL = `_E5;		9'd267: freqL = `_E5;
			9'd268: freqL = `_E5;		9'd269: freqL = `_E5;
			9'd270: freqL = `_E5;		9'd271: freqL = `sil;
			9'd272: freqL = `_E5;		9'd273: freqL = `_E5;
			9'd274: freqL = `_E5;		9'd275: freqL = `_E5;
			9'd276: freqL = `_E5;		9'd277: freqL = `_E5;
			9'd278: freqL = `_E5;		9'd279: freqL = `_E5;
			9'd280: freqL = `_E5;		9'd281: freqL = `_E5;
			9'd282: freqL = `_E5;		9'd283: freqL = `_E5;
			9'd284: freqL = `_E5;		9'd285: freqL = `_E5;
			9'd286: freqL = `_E5;		9'd287: freqL = `sil;
			9'd288: freqL = `_E5;		9'd289: freqL = `_E5;
			9'd290: freqL = `_E5;		9'd291: freqL = `_E5;
			9'd292: freqL = `_E5;		9'd293: freqL = `_E5;
			9'd294: freqL = `_E5;		9'd295: freqL = `sil;
			9'd296: freqL = `_E5;		9'd297: freqL = `_E5;
			9'd298: freqL = `_E5;		9'd299: freqL = `_E5;
			9'd300: freqL = `_E5;		9'd301: freqL = `_E5;
			9'd302: freqL = `_E5;		9'd303: freqL = `sil;
			9'd304: freqL = `_E5;		9'd305: freqL = `_E5;
			9'd306: freqL = `_E5;		9'd307: freqL = `_E5;
			9'd308: freqL = `_E5;		9'd309: freqL = `_E5;
			9'd310: freqL = `_E5;		9'd311: freqL = `_E5;
			9'd312: freqL = `_E5;		9'd313: freqL = `_E5;
			9'd314: freqL = `_E5;		9'd315: freqL = `_E5;
			9'd316: freqL = `_E5;		9'd317: freqL = `_E5;
			9'd318: freqL = `_E5;		9'd319: freqL = `sil;
			// --- Measure 6 ---
			9'd320: freqL = `_E5;		9'd321: freqL = `_E5;
			9'd322: freqL = `_E5;		9'd323: freqL = `_E5;
			9'd324: freqL = `_E5;		9'd325: freqL = `_E5;
			9'd326: freqL = `_E5;		9'd327: freqL = `_E5;
			9'd328: freqL = `_G5;		9'd329: freqL = `_G5;
			9'd330: freqL = `_G5;		9'd331: freqL = `_G5;
			9'd332: freqL = `_G5;		9'd333: freqL = `_G5;
			9'd334: freqL = `_G5;		9'd335: freqL = `_G5;
			9'd336: freqL = `_C5;		9'd337: freqL = `_C5;
			9'd338: freqL = `_C5;		9'd339: freqL = `_C5;
			9'd340: freqL = `_C5;		9'd341: freqL = `_C5;
			9'd342: freqL = `_C5;		9'd343: freqL = `_C5;
			9'd344: freqL = `_D5;		9'd345: freqL = `_D5;
			9'd346: freqL = `_D5;		9'd347: freqL = `_D5;
			9'd348: freqL = `_D5;		9'd349: freqL = `_D5;
			9'd350: freqL = `_D5;		9'd351: freqL = `_D5;
			9'd352: freqL = `_E5;		9'd353: freqL = `_E5;
			9'd354: freqL = `_E5;		9'd355: freqL = `_E5;
			9'd356: freqL = `_E5;		9'd357: freqL = `_E5;
			9'd358: freqL = `_E5;		9'd359: freqL = `_E5;
			9'd360: freqL = `_E5;		9'd361: freqL = `_E5;
			9'd362: freqL = `_E5;		9'd363: freqL = `_E5;
			9'd364: freqL = `_E5;		9'd365: freqL = `_E5;
			9'd366: freqL = `_E5;		9'd367: freqL = `_E5;
			9'd368: freqL = `_E5;		9'd369: freqL = `_E5;
			9'd370: freqL = `_E5;		9'd371: freqL = `_E5;
			9'd372: freqL = `_E5;		9'd373: freqL = `_E5;
			9'd374: freqL = `_E5;		9'd375: freqL = `_E5;
			9'd376: freqL = `_E5;		9'd377: freqL = `_E5;
			9'd378: freqL = `_E5;		9'd379: freqL = `_E5;
			9'd380: freqL = `_E5;		9'd381: freqL = `_E5;
			9'd382: freqL = `_E5;		9'd383: freqL = `_E5;
			// --- Measure 7 ---
			9'd384: freqL = `_F5;		9'd385: freqL = `_F5;
			9'd386: freqL = `_F5;		9'd387: freqL = `_F5;
			9'd388: freqL = `_F5;		9'd389: freqL = `_F5;
			9'd390: freqL = `_F5;		9'd391: freqL = `sil;
			9'd392: freqL = `_F5;		9'd393: freqL = `_F5;
			9'd394: freqL = `_F5;		9'd395: freqL = `_F5;
			9'd396: freqL = `_F5;		9'd397: freqL = `_F5;
			9'd398: freqL = `_F5;		9'd399: freqL = `sil;
			9'd400: freqL = `_F5;		9'd401: freqL = `_F5;
			9'd402: freqL = `_F5;		9'd403: freqL = `_F5;
			9'd404: freqL = `_F5;		9'd405: freqL = `_F5;
			9'd406: freqL = `_F5;		9'd407: freqL = `_F5;
			9'd408: freqL = `_F5;		9'd409: freqL = `_F5;
			9'd410: freqL = `_F5;		9'd411: freqL = `sil;
			9'd412: freqL = `_F5;		9'd413: freqL = `_F5;
			9'd414: freqL = `_F5;		9'd415: freqL = `sil;
			9'd416: freqL = `_F5;		9'd417: freqL = `_F5;
			9'd418: freqL = `_F5;		9'd419: freqL = `_F5;
			9'd420: freqL = `_F5;		9'd421: freqL = `_F5;
			9'd422: freqL = `_F5;		9'd423: freqL = `_F5;
			9'd424: freqL = `_E5;		9'd425: freqL = `_E5;
			9'd426: freqL = `_E5;		9'd427: freqL = `_E5;
			9'd428: freqL = `_E5;		9'd429: freqL = `_E5;
			9'd430: freqL = `_E5;		9'd431: freqL = `sil;
			9'd432: freqL = `_E5;		9'd433: freqL = `_E5;
			9'd434: freqL = `_E5;		9'd435: freqL = `_E5;
			9'd436: freqL = `_E5;		9'd437: freqL = `_E5;
			9'd438: freqL = `_E5;		9'd439: freqL = `_E5;
			9'd440: freqL = `_E5;		9'd441: freqL = `_E5;
			9'd442: freqL = `_E5;		9'd443: freqL = `sil;
			9'd444: freqL = `_E5;		9'd445: freqL = `_E5;
			9'd446: freqL = `_E5;		9'd447: freqL = `_E5;
			// --- Measure 8 ---
			9'd448: freqL = `_G5;		9'd449: freqL = `_G5;
			9'd450: freqL = `_G5;		9'd451: freqL = `_G5;
			9'd452: freqL = `_G5;		9'd453: freqL = `_G5;
			9'd454: freqL = `_G5;		9'd455: freqL = `sil;
			9'd456: freqL = `_G5;		9'd457: freqL = `_G5;
			9'd458: freqL = `_G5;		9'd459: freqL = `_G5;
			9'd460: freqL = `_G5;		9'd461: freqL = `_G5;
			9'd462: freqL = `_G5;		9'd463: freqL = `_G5;
			9'd464: freqL = `_F5;		9'd465: freqL = `_F5;
			9'd466: freqL = `_F5;		9'd467: freqL = `_F5;
			9'd468: freqL = `_F5;		9'd469: freqL = `_F5;
			9'd470: freqL = `_F5;		9'd471: freqL = `_F5;
			9'd472: freqL = `_D5;		9'd473: freqL = `_D5;
			9'd474: freqL = `_D5;		9'd475: freqL = `_D5;
			9'd476: freqL = `_D5;		9'd477: freqL = `_D5;
			9'd478: freqL = `_D5;		9'd479: freqL = `_D5;
			9'd480: freqL = `_C5;		9'd481: freqL = `_C5;
			9'd482: freqL = `_C5;		9'd483: freqL = `_C5;
			9'd484: freqL = `_C5;		9'd485: freqL = `_C5;
			9'd486: freqL = `_C5;		9'd487: freqL = `_C5;
			9'd488: freqL = `_C5;		9'd489: freqL = `_C5;
			9'd490: freqL = `_C5;		9'd491: freqL = `_C5;
			9'd492: freqL = `_C5;		9'd493: freqL = `_C5;
			9'd494: freqL = `_C5;		9'd495: freqL = `_C5;
			9'd496: freqL = `_C5;		9'd497: freqL = `_C5;
			9'd498: freqL = `_C5;		9'd499: freqL = `_C5;
			9'd500: freqL = `_C5;		9'd501: freqL = `_C5;
			9'd502: freqL = `_C5;		9'd503: freqL = `_C5;
			9'd504: freqL = `_C5;		9'd505: freqL = `_C5;
			9'd506: freqL = `_C5;		9'd507: freqL = `_C5;
			9'd508: freqL = `_C5;		9'd509: freqL = `_C5;
			9'd510: freqL = `_C5;		9'd511: freqL = `_C5;
		endcase
	end

    // freqR
	always @* begin
		case(beat)
			// --- Measure 1 ---
			9'd0: freqR = `_C5;		9'd1: freqR = `_C5;
			9'd2: freqR = `_C5;		9'd3: freqR = `_C5;
			9'd4: freqR = `_C5;		9'd5: freqR = `_C5;
			9'd6: freqR = `_C5;		9'd7: freqR = `_C5;
			9'd8: freqR = `_C5;		9'd9: freqR = `_C5;
			9'd10: freqR = `_C5;		9'd11: freqR = `_C5;
			9'd12: freqR = `_C5;		9'd13: freqR = `_C5;
			9'd14: freqR = `_C5;		9'd15: freqR = `_C5;
			9'd16: freqR = `_G4;		9'd17: freqR = `_G4;
			9'd18: freqR = `_G4;		9'd19: freqR = `_G4;
			9'd20: freqR = `_G4;		9'd21: freqR = `_G4;
			9'd22: freqR = `_G4;		9'd23: freqR = `_G4;
			9'd24: freqR = `_G4;		9'd25: freqR = `_G4;
			9'd26: freqR = `_G4;		9'd27: freqR = `_G4;
			9'd28: freqR = `_G4;		9'd29: freqR = `_G4;
			9'd30: freqR = `_G4;		9'd31: freqR = `_G4;
			9'd32: freqR = `_C5;		9'd33: freqR = `_C5;
			9'd34: freqR = `_C5;		9'd35: freqR = `_C5;
			9'd36: freqR = `_C5;		9'd37: freqR = `_C5;
			9'd38: freqR = `_C5;		9'd39: freqR = `_C5;
			9'd40: freqR = `_C5;		9'd41: freqR = `_C5;
			9'd42: freqR = `_C5;		9'd43: freqR = `_C5;
			9'd44: freqR = `_C5;		9'd45: freqR = `_C5;
			9'd46: freqR = `_C5;		9'd47: freqR = `_C5;
			9'd48: freqR = `_G4;		9'd49: freqR = `_G4;
			9'd50: freqR = `_G4;		9'd51: freqR = `_G4;
			9'd52: freqR = `_G4;		9'd53: freqR = `_G4;
			9'd54: freqR = `_G4;		9'd55: freqR = `_G4;
			9'd56: freqR = `_G4;		9'd57: freqR = `_G4;
			9'd58: freqR = `_G4;		9'd59: freqR = `_G4;
			9'd60: freqR = `_G4;		9'd61: freqR = `_G4;
			9'd62: freqR = `_G4;		9'd63: freqR = `_G4;
			// --- Measure 2 ---
			9'd64: freqR = `_C5;		9'd65: freqR = `_C5;
			9'd66: freqR = `_C5;		9'd67: freqR = `_C5;
			9'd68: freqR = `_C5;		9'd69: freqR = `_C5;
			9'd70: freqR = `_C5;		9'd71: freqR = `_C5;
			9'd72: freqR = `_C5;		9'd73: freqR = `_C5;
			9'd74: freqR = `_C5;		9'd75: freqR = `_C5;
			9'd76: freqR = `_C5;		9'd77: freqR = `_C5;
			9'd78: freqR = `_C5;		9'd79: freqR = `_C5;
			9'd80: freqR = `_G4;		9'd81: freqR = `_G4;
			9'd82: freqR = `_G4;		9'd83: freqR = `_G4;
			9'd84: freqR = `_G4;		9'd85: freqR = `_G4;
			9'd86: freqR = `_G4;		9'd87: freqR = `_G4;
			9'd88: freqR = `_G4;		9'd89: freqR = `_G4;
			9'd90: freqR = `_G4;		9'd91: freqR = `_G4;
			9'd92: freqR = `_G4;		9'd93: freqR = `_G4;
			9'd94: freqR = `_G4;		9'd95: freqR = `_G4;
			9'd96: freqR = `_C5;		9'd97: freqR = `_C5;
			9'd98: freqR = `_C5;		9'd99: freqR = `_C5;
			9'd100: freqR = `_C5;		9'd101: freqR = `_C5;
			9'd102: freqR = `_C5;		9'd103: freqR = `_C5;
			9'd104: freqR = `_G4;		9'd105: freqR = `_G4;
			9'd106: freqR = `_G4;		9'd107: freqR = `_G4;
			9'd108: freqR = `_G4;		9'd109: freqR = `_G4;
			9'd110: freqR = `_G4;		9'd111: freqR = `_G4;
			9'd112: freqR = `_A4;		9'd113: freqR = `_A4;
			9'd114: freqR = `_A4;		9'd115: freqR = `_A4;
			9'd116: freqR = `_A4;		9'd117: freqR = `_A4;
			9'd118: freqR = `_A4;		9'd119: freqR = `_A4;
			9'd120: freqR = `_B4;		9'd121: freqR = `_B4;
			9'd122: freqR = `_B4;		9'd123: freqR = `_B4;
			9'd124: freqR = `_B4;		9'd125: freqR = `_B4;
			9'd126: freqR = `_B4;		9'd127: freqR = `_B4;
			// --- Measure 3 ---
			9'd128: freqR = `_D5;		9'd129: freqR = `_D5;
			9'd130: freqR = `_D5;		9'd131: freqR = `_D5;
			9'd132: freqR = `_D5;		9'd133: freqR = `_D5;
			9'd134: freqR = `_D5;		9'd135: freqR = `_D5;
			9'd136: freqR = `_D5;		9'd137: freqR = `_D5;
			9'd138: freqR = `_D5;		9'd139: freqR = `_D5;
			9'd140: freqR = `_D5;		9'd141: freqR = `_D5;
			9'd142: freqR = `_D5;		9'd143: freqR = `_D5;
			9'd144: freqR = `_F4;		9'd145: freqR = `_F4;
			9'd146: freqR = `_F4;		9'd147: freqR = `_F4;
			9'd148: freqR = `_F4;		9'd149: freqR = `_F4;
			9'd150: freqR = `_F4;		9'd151: freqR = `_F4;
			9'd152: freqR = `_F4;		9'd153: freqR = `_F4;
			9'd154: freqR = `_F4;		9'd155: freqR = `_F4;
			9'd156: freqR = `_F4;		9'd157: freqR = `_F4;
			9'd158: freqR = `_F4;		9'd159: freqR = `_F4;
			9'd160: freqR = `_C5;		9'd161: freqR = `_C5;
			9'd162: freqR = `_C5;		9'd163: freqR = `_C5;
			9'd164: freqR = `_C5;		9'd165: freqR = `_C5;
			9'd166: freqR = `_C5;		9'd167: freqR = `_C5;
			9'd168: freqR = `_C5;		9'd169: freqR = `_C5;
			9'd170: freqR = `_C5;		9'd171: freqR = `_C5;
			9'd172: freqR = `_C5;		9'd173: freqR = `_C5;
			9'd174: freqR = `_C5;		9'd175: freqR = `_C5;
			9'd176: freqR = `_E4;		9'd177: freqR = `_E4;
			9'd178: freqR = `_E4;		9'd179: freqR = `_E4;
			9'd180: freqR = `_E4;		9'd181: freqR = `_E4;
			9'd182: freqR = `_E4;		9'd183: freqR = `_E4;
			9'd184: freqR = `_E4;		9'd185: freqR = `_E4;
			9'd186: freqR = `_E4;		9'd187: freqR = `_E4;
			9'd188: freqR = `_E4;		9'd189: freqR = `_E4;
			9'd190: freqR = `_E4;		9'd191: freqR = `_E4;
			// --- Measure 4 ---
			9'd192: freqR = `_G4;		9'd193: freqR = `_G4;
			9'd194: freqR = `_G4;		9'd195: freqR = `_G4;
			9'd196: freqR = `_G4;		9'd197: freqR = `_G4;
			9'd198: freqR = `_G4;		9'd199: freqR = `_G4;
			9'd200: freqR = `_G4;		9'd201: freqR = `_G4;
			9'd202: freqR = `_G4;		9'd203: freqR = `_G4;
			9'd204: freqR = `_G4;		9'd205: freqR = `_G4;
			9'd206: freqR = `_G4;		9'd207: freqR = `_G4;
			9'd208: freqR = `_F4;		9'd209: freqR = `_F4;
			9'd210: freqR = `_F4;		9'd211: freqR = `_F4;
			9'd212: freqR = `_F4;		9'd213: freqR = `_F4;
			9'd214: freqR = `_F4;		9'd215: freqR = `_F4;
			9'd216: freqR = `_F4;		9'd217: freqR = `_F4;
			9'd218: freqR = `_F4;		9'd219: freqR = `_F4;
			9'd220: freqR = `_F4;		9'd221: freqR = `_F4;
			9'd222: freqR = `_F4;		9'd223: freqR = `_F4;
			9'd224: freqR = `_D4;		9'd225: freqR = `_D4;
			9'd226: freqR = `_D4;		9'd227: freqR = `_D4;
			9'd228: freqR = `_D4;		9'd229: freqR = `_D4;
			9'd230: freqR = `_D4;		9'd231: freqR = `_D4;
			9'd232: freqR = `_D4;		9'd233: freqR = `_D4;
			9'd234: freqR = `_D4;		9'd235: freqR = `_D4;
			9'd236: freqR = `_D4;		9'd237: freqR = `_D4;
			9'd238: freqR = `_D4;		9'd239: freqR = `_D4;
			9'd240: freqR = `_B4;		9'd241: freqR = `_B4;
			9'd242: freqR = `_B4;		9'd243: freqR = `_B4;
			9'd244: freqR = `_B4;		9'd245: freqR = `_B4;
			9'd246: freqR = `_B4;		9'd247: freqR = `_B4;
			9'd248: freqR = `_B4;		9'd249: freqR = `_B4;
			9'd250: freqR = `_B4;		9'd251: freqR = `_B4;
			9'd252: freqR = `_B4;		9'd253: freqR = `_B4;
			9'd254: freqR = `_B4;		9'd255: freqR = `_B4;
			// --- Measure 5 ---
			9'd256: freqR = `_C5;		9'd257: freqR = `_C5;
			9'd258: freqR = `_C5;		9'd259: freqR = `_C5;
			9'd260: freqR = `_C5;		9'd261: freqR = `_C5;
			9'd262: freqR = `_C5;		9'd263: freqR = `_C5;
			9'd264: freqR = `_C5;		9'd265: freqR = `_C5;
			9'd266: freqR = `_C5;		9'd267: freqR = `_C5;
			9'd268: freqR = `_C5;		9'd269: freqR = `_C5;
			9'd270: freqR = `_C5;		9'd271: freqR = `_C5;
			9'd272: freqR = `_G4;		9'd273: freqR = `_G4;
			9'd274: freqR = `_G4;		9'd275: freqR = `_G4;
			9'd276: freqR = `_G4;		9'd277: freqR = `_G4;
			9'd278: freqR = `_G4;		9'd279: freqR = `_G4;
			9'd280: freqR = `_G4;		9'd281: freqR = `_G4;
			9'd282: freqR = `_G4;		9'd283: freqR = `_G4;
			9'd284: freqR = `_G4;		9'd285: freqR = `_G4;
			9'd286: freqR = `_G4;		9'd287: freqR = `_G4;
			9'd288: freqR = `_C5;		9'd289: freqR = `_C5;
			9'd290: freqR = `_C5;		9'd291: freqR = `_C5;
			9'd292: freqR = `_C5;		9'd293: freqR = `_C5;
			9'd294: freqR = `_C5;		9'd295: freqR = `_C5;
			9'd296: freqR = `_C5;		9'd297: freqR = `_C5;
			9'd298: freqR = `_C5;		9'd299: freqR = `_C5;
			9'd300: freqR = `_C5;		9'd301: freqR = `_C5;
			9'd302: freqR = `_C5;		9'd303: freqR = `_C5;
			9'd304: freqR = `_G4;		9'd305: freqR = `_G4;
			9'd306: freqR = `_G4;		9'd307: freqR = `_G4;
			9'd308: freqR = `_G4;		9'd309: freqR = `_G4;
			9'd310: freqR = `_G4;		9'd311: freqR = `_G4;
			9'd312: freqR = `_G4;		9'd313: freqR = `_G4;
			9'd314: freqR = `_G4;		9'd315: freqR = `_G4;
			9'd316: freqR = `_G4;		9'd317: freqR = `_G4;
			9'd318: freqR = `_G4;		9'd319: freqR = `_G4;
			// --- Measure 6 ---
			9'd320: freqR = `_C5;		9'd321: freqR = `_C5;
			9'd322: freqR = `_C5;		9'd323: freqR = `_C5;
			9'd324: freqR = `_C5;		9'd325: freqR = `_C5;
			9'd326: freqR = `_C5;		9'd327: freqR = `_C5;
			9'd328: freqR = `_C5;		9'd329: freqR = `_C5;
			9'd330: freqR = `_C5;		9'd331: freqR = `_C5;
			9'd332: freqR = `_C5;		9'd333: freqR = `_C5;
			9'd334: freqR = `_C5;		9'd335: freqR = `_C5;
			9'd336: freqR = `_G4;		9'd337: freqR = `_G4;
			9'd338: freqR = `_G4;		9'd339: freqR = `_G4;
			9'd340: freqR = `_G4;		9'd341: freqR = `_G4;
			9'd342: freqR = `_G4;		9'd343: freqR = `_G4;
			9'd344: freqR = `_G4;		9'd345: freqR = `_G4;
			9'd346: freqR = `_G4;		9'd347: freqR = `_G4;
			9'd348: freqR = `_G4;		9'd349: freqR = `_G4;
			9'd350: freqR = `_G4;		9'd351: freqR = `_G4;
			9'd352: freqR = `_C5;		9'd353: freqR = `_C5;
			9'd354: freqR = `_C5;		9'd355: freqR = `_C5;
			9'd356: freqR = `_C5;		9'd357: freqR = `_C5;
			9'd358: freqR = `_C5;		9'd359: freqR = `_C5;
			9'd360: freqR = `_G4;		9'd361: freqR = `_G4;
			9'd362: freqR = `_G4;		9'd363: freqR = `_G4;
			9'd364: freqR = `_G4;		9'd365: freqR = `_G4;
			9'd366: freqR = `_G4;		9'd367: freqR = `_G4;
			9'd368: freqR = `_A4;		9'd369: freqR = `_A4;
			9'd370: freqR = `_A4;		9'd371: freqR = `_A4;
			9'd372: freqR = `_A4;		9'd373: freqR = `_A4;
			9'd374: freqR = `_A4;		9'd375: freqR = `_A4;
			9'd376: freqR = `_B4;		9'd377: freqR = `_B4;
			9'd378: freqR = `_B4;		9'd379: freqR = `_B4;
			9'd380: freqR = `_B4;		9'd381: freqR = `_B4;
			9'd382: freqR = `_B4;		9'd383: freqR = `_B4;
			// --- Measure 7 ---
			9'd384: freqR = `_D5;		9'd385: freqR = `_D5;
			9'd386: freqR = `_D5;		9'd387: freqR = `_D5;
			9'd388: freqR = `_D5;		9'd389: freqR = `_D5;
			9'd390: freqR = `_D5;		9'd391: freqR = `_D5;
			9'd392: freqR = `_D5;		9'd393: freqR = `_D5;
			9'd394: freqR = `_D5;		9'd395: freqR = `_D5;
			9'd396: freqR = `_D5;		9'd397: freqR = `_D5;
			9'd398: freqR = `_D5;		9'd399: freqR = `_D5;
			9'd400: freqR = `_F4;		9'd401: freqR = `_F4;
			9'd402: freqR = `_F4;		9'd403: freqR = `_F4;
			9'd404: freqR = `_F4;		9'd405: freqR = `_F4;
			9'd406: freqR = `_F4;		9'd407: freqR = `_F4;
			9'd408: freqR = `_F4;		9'd409: freqR = `_F4;
			9'd410: freqR = `_F4;		9'd411: freqR = `_F4;
			9'd412: freqR = `_F4;		9'd413: freqR = `_F4;
			9'd414: freqR = `_F4;		9'd415: freqR = `_F4;
			9'd416: freqR = `_C5;		9'd417: freqR = `_C5;
			9'd418: freqR = `_C5;		9'd419: freqR = `_C5;
			9'd420: freqR = `_C5;		9'd421: freqR = `_C5;
			9'd422: freqR = `_C5;		9'd423: freqR = `_C5;
			9'd424: freqR = `_C5;		9'd425: freqR = `_C5;
			9'd426: freqR = `_C5;		9'd427: freqR = `_C5;
			9'd428: freqR = `_C5;		9'd429: freqR = `_C5;
			9'd430: freqR = `_C5;		9'd431: freqR = `_C5;
			9'd432: freqR = `_E4;		9'd433: freqR = `_E4;
			9'd434: freqR = `_E4;		9'd435: freqR = `_E4;
			9'd436: freqR = `_E4;		9'd437: freqR = `_E4;
			9'd438: freqR = `_E4;		9'd439: freqR = `_E4;
			9'd440: freqR = `_E4;		9'd441: freqR = `_E4;
			9'd442: freqR = `_E4;		9'd443: freqR = `_E4;
			9'd444: freqR = `_E4;		9'd445: freqR = `_E4;
			9'd446: freqR = `_E4;		9'd447: freqR = `_E4;
			// --- Measure 8 ---
			9'd448: freqR = `_C5;		9'd449: freqR = `_C5;
			9'd450: freqR = `_C5;		9'd451: freqR = `_C5;
			9'd452: freqR = `_C5;		9'd453: freqR = `_C5;
			9'd454: freqR = `_C5;		9'd455: freqR = `_C5;
			9'd456: freqR = `_C5;		9'd457: freqR = `_C5;
			9'd458: freqR = `_C5;		9'd459: freqR = `_C5;
			9'd460: freqR = `_C5;		9'd461: freqR = `_C5;
			9'd462: freqR = `_C5;		9'd463: freqR = `_C5;
			9'd464: freqR = `_G4;		9'd465: freqR = `_G4;
			9'd466: freqR = `_G4;		9'd467: freqR = `_G4;
			9'd468: freqR = `_G4;		9'd469: freqR = `_G4;
			9'd470: freqR = `_G4;		9'd471: freqR = `_G4;
			9'd472: freqR = `_G4;		9'd473: freqR = `_G4;
			9'd474: freqR = `_G4;		9'd475: freqR = `_G4;
			9'd476: freqR = `_G4;		9'd477: freqR = `_G4;
			9'd478: freqR = `_G4;		9'd479: freqR = `_G4;
			9'd480: freqR = `_C4;		9'd481: freqR = `_C4;
			9'd482: freqR = `_C4;		9'd483: freqR = `_C4;
			9'd484: freqR = `_C4;		9'd485: freqR = `_C4;
			9'd486: freqR = `_C4;		9'd487: freqR = `_C4;
			9'd488: freqR = `_C4;		9'd489: freqR = `_C4;
			9'd490: freqR = `_C4;		9'd491: freqR = `_C4;
			9'd492: freqR = `_C4;		9'd493: freqR = `_C4;
			9'd494: freqR = `_C4;		9'd495: freqR = `_C4;
			9'd496: freqR = `sil;		9'd497: freqR = `sil;
			9'd498: freqR = `sil;		9'd499: freqR = `sil;
			9'd500: freqR = `sil;		9'd501: freqR = `sil;
			9'd502: freqR = `sil;		9'd503: freqR = `sil;
			9'd504: freqR = `sil;		9'd505: freqR = `sil;
			9'd506: freqR = `sil;		9'd507: freqR = `sil;
			9'd508: freqR = `sil;		9'd509: freqR = `sil;
			9'd510: freqR = `sil;		9'd511: freqR = `sil;
		endcase
	end


endmodule

module music2(
	input [8:0] beat,
	output reg [31:0] freqL,
	output reg [31:0] freqR
	);

	// freqL
	always @* begin
		case(beat)
			// --- Measure 1 ---
			9'd0: freqL = `_G4;		9'd1: freqL = `_G4;
			9'd2: freqL = `_G4;		9'd3: freqL = `_G4;
			9'd4: freqL = `_G4;		9'd5: freqL = `_G4;
			9'd6: freqL = `_G4;		9'd7: freqL = `_G4;
			9'd8: freqL = `bB4;		9'd9: freqL = `bB4;
			9'd10: freqL = `bB4;		9'd11: freqL = `bB4;
			9'd12: freqL = `bB4;		9'd13: freqL = `bB4;
			9'd14: freqL = `bB4;		9'd15: freqL = `bB4;
			9'd16: freqL = `_C5;		9'd17: freqL = `_C5;
			9'd18: freqL = `_C5;		9'd19: freqL = `_C5;
			9'd20: freqL = `_C5;		9'd21: freqL = `_C5;
			9'd22: freqL = `_C5;		9'd23: freqL = `_C5;
			9'd24: freqL = `_C5;		9'd25: freqL = `_C5;
			9'd26: freqL = `_C5;		9'd27: freqL = `_C5;
			9'd28: freqL = `bA4;		9'd29: freqL = `bA4;
			9'd30: freqL = `bA4;		9'd31: freqL = `bA4;
			9'd32: freqL = `bA4;		9'd33: freqL = `bA4;
			9'd34: freqL = `bA4;		9'd35: freqL = `bA4;
			9'd36: freqL = `bA4;		9'd37: freqL = `bA4;
			9'd38: freqL = `bA4;		9'd39: freqL = `bA4;
			9'd40: freqL = `_G4;		9'd41: freqL = `_G4;
			9'd42: freqL = `_G4;		9'd43: freqL = `_G4;
			9'd44: freqL = `_G4;		9'd45: freqL = `_G4;
			9'd46: freqL = `_G4;		9'd47: freqL = `_G4;
			9'd48: freqL = `_F4;		9'd49: freqL = `_F4;
			9'd50: freqL = `_F4;		9'd51: freqL = `_F4;
			9'd52: freqL = `_F4;		9'd53: freqL = `_F4;
			9'd54: freqL = `_F4;		9'd55: freqL = `_F4;
			9'd56: freqL = `bE4;		9'd57: freqL = `bE4;
			9'd58: freqL = `bE4;		9'd59: freqL = `bE4;
			9'd60: freqL = `bE4;		9'd61: freqL = `bE4;
			9'd62: freqL = `bE4;		9'd63: freqL = `bE4;
			// --- Measure 2 ---
			9'd64: freqL = `_F4;		9'd65: freqL = `_F4;
			9'd66: freqL = `_F4;		9'd67: freqL = `_F4;
			9'd68: freqL = `_F4;		9'd69: freqL = `_F4;
			9'd70: freqL = `_F4;		9'd71: freqL = `_F4;
			9'd72: freqL = `_C5;		9'd73: freqL = `_C5;
			9'd74: freqL = `_C5;		9'd75: freqL = `_C5;
			9'd76: freqL = `_C5;		9'd77: freqL = `_C5;
			9'd78: freqL = `_C5;		9'd79: freqL = `_C5;
			9'd80: freqL = `bB4;		9'd81: freqL = `bB4;
			9'd82: freqL = `bB4;		9'd83: freqL = `bB4;
			9'd84: freqL = `bB4;		9'd85: freqL = `bB4;
			9'd86: freqL = `bB4;		9'd87: freqL = `bB4;
			9'd88: freqL = `_C5;		9'd89: freqL = `_C5;
			9'd90: freqL = `_C5;		9'd91: freqL = `_C5;
			9'd92: freqL = `_G4;		9'd93: freqL = `_G4;
			9'd94: freqL = `_G4;		9'd95: freqL = `_G4;
			9'd96: freqL = `_G4;		9'd97: freqL = `_G4;
			9'd98: freqL = `_G4;		9'd99: freqL = `_G4;
			9'd100: freqL = `_G4;		9'd101: freqL = `_G4;
			9'd102: freqL = `_G4;		9'd103: freqL = `_G4;
			9'd104: freqL = `_F4;		9'd105: freqL = `_F4;
			9'd106: freqL = `_F4;		9'd107: freqL = `_F4;
			9'd108: freqL = `_F4;		9'd109: freqL = `_F4;
			9'd110: freqL = `_F4;		9'd111: freqL = `_F4;
			9'd112: freqL = `bE4;		9'd113: freqL = `bE4;
			9'd114: freqL = `bE4;		9'd115: freqL = `bE4;
			9'd116: freqL = `bE4;		9'd117: freqL = `bE4;
			9'd118: freqL = `bE4;		9'd119: freqL = `bE4;
			9'd120: freqL = `bE4;		9'd121: freqL = `bE4;
			9'd122: freqL = `bE4;		9'd123: freqL = `bE4;
			9'd124: freqL = `bE4;		9'd125: freqL = `bE4;
			9'd126: freqL = `bE4;		9'd127: freqL = `bE4;
			// --- Measure 3 ---
			9'd128: freqL = `_C4;		9'd129: freqL = `_C4;
			9'd130: freqL = `_C4;		9'd131: freqL = `_C4;
			9'd132: freqL = `_C4;		9'd133: freqL = `_C4;
			9'd134: freqL = `_C4;		9'd135: freqL = `_C4;
			9'd136: freqL = `bE4;		9'd137: freqL = `bE4;
			9'd138: freqL = `bE4;		9'd139: freqL = `bE4;
			9'd140: freqL = `bE4;		9'd141: freqL = `bE4;
			9'd142: freqL = `bE4;		9'd143: freqL = `bE4;
			9'd144: freqL = `_F4;		9'd145: freqL = `_F4;
			9'd146: freqL = `_F4;		9'd147: freqL = `_F4;
			9'd148: freqL = `_F4;		9'd149: freqL = `_F4;
			9'd150: freqL = `_F4;		9'd151: freqL = `_F4;
			9'd152: freqL = `_F4;		9'd153: freqL = `_F4;
			9'd154: freqL = `_F4;		9'd155: freqL = `_F4;
			9'd156: freqL = `_D4;		9'd157: freqL = `_D4;
			9'd158: freqL = `_D4;		9'd159: freqL = `_D4;
			9'd160: freqL = `_D4;		9'd161: freqL = `_D4;
			9'd162: freqL = `_D4;		9'd163: freqL = `_D4;
			9'd164: freqL = `_D4;		9'd165: freqL = `_D4;
			9'd166: freqL = `_D4;		9'd167: freqL = `_D4;
			9'd168: freqL = `bA4;		9'd169: freqL = `bA4;
			9'd170: freqL = `bA4;		9'd171: freqL = `bA4;
			9'd172: freqL = `bA4;		9'd173: freqL = `bA4;
			9'd174: freqL = `bA4;		9'd175: freqL = `bA4;
			9'd176: freqL = `_G4;		9'd177: freqL = `_G4;
			9'd178: freqL = `_G4;		9'd179: freqL = `_G4;
			9'd180: freqL = `_G4;		9'd181: freqL = `_G4;
			9'd182: freqL = `_G4;		9'd183: freqL = `_G4;
			9'd184: freqL = `_G5;		9'd185: freqL = `_G5;
			9'd186: freqL = `_G5;		9'd187: freqL = `_G5;
			9'd188: freqL = `_G5;		9'd189: freqL = `_G5;
			9'd190: freqL = `_G5;		9'd191: freqL = `_G5;
			// --- Measure 4 ---
			9'd192: freqL = `_F5;		9'd193: freqL = `_F5;
			9'd194: freqL = `_F5;		9'd195: freqL = `_F5;
			9'd196: freqL = `_F5;		9'd197: freqL = `_F5;
			9'd198: freqL = `_F5;		9'd199: freqL = `_F5;
			9'd200: freqL = `_D5;		9'd201: freqL = `_D5;
			9'd202: freqL = `_D5;		9'd203: freqL = `_D5;
			9'd204: freqL = `_D5;		9'd205: freqL = `_D5;
			9'd206: freqL = `_D5;		9'd207: freqL = `_D5;
			9'd208: freqL = `bE5;		9'd209: freqL = `bE5;
			9'd210: freqL = `bE5;		9'd211: freqL = `bE5;
			9'd212: freqL = `bE5;		9'd213: freqL = `bE5;
			9'd214: freqL = `bE5;		9'd215: freqL = `bE5;
			9'd216: freqL = `bE5;		9'd217: freqL = `bE5;
			9'd218: freqL = `bE5;		9'd219: freqL = `bE5;
			9'd220: freqL = `_D5;		9'd221: freqL = `_D5;
			9'd222: freqL = `_D5;		9'd223: freqL = `_D5;
			9'd224: freqL = `_D5;		9'd225: freqL = `_D5;
			9'd226: freqL = `_D5;		9'd227: freqL = `_D5;
			9'd228: freqL = `_D5;		9'd229: freqL = `_D5;
			9'd230: freqL = `_D5;		9'd231: freqL = `_D5;
			9'd232: freqL = `bB4;		9'd233: freqL = `bB4;
			9'd234: freqL = `bB4;		9'd235: freqL = `bB4;
			9'd236: freqL = `bB4;		9'd237: freqL = `bB4;
			9'd238: freqL = `bB4;		9'd239: freqL = `bB4;
			9'd240: freqL = `_C5;		9'd241: freqL = `_C5;
			9'd242: freqL = `_C5;		9'd243: freqL = `_C5;
			9'd244: freqL = `_C5;		9'd245: freqL = `_C5;
			9'd246: freqL = `_C5;		9'd247: freqL = `_C5;
			9'd248: freqL = `bB4;		9'd249: freqL = `bB4;
			9'd250: freqL = `bB4;		9'd251: freqL = `bB4;
			9'd252: freqL = `bB4;		9'd253: freqL = `bB4;
			9'd254: freqL = `bB4;		9'd255: freqL = `bB4;
			// --- Measure 5 ---
			9'd256: freqL = `_G4;		9'd257: freqL = `_G4;
			9'd258: freqL = `_G4;		9'd259: freqL = `_G4;
			9'd260: freqL = `_G4;		9'd261: freqL = `_G4;
			9'd262: freqL = `_G4;		9'd263: freqL = `_G4;
			9'd264: freqL = `bB4;		9'd265: freqL = `bB4;
			9'd266: freqL = `bB4;		9'd267: freqL = `bB4;
			9'd268: freqL = `bB4;		9'd269: freqL = `bB4;
			9'd270: freqL = `bB4;		9'd271: freqL = `bB4;
			9'd272: freqL = `_C5;		9'd273: freqL = `_C5;
			9'd274: freqL = `_C5;		9'd275: freqL = `_C5;
			9'd276: freqL = `_C5;		9'd277: freqL = `_C5;
			9'd278: freqL = `_C5;		9'd279: freqL = `_C5;
			9'd280: freqL = `_C5;		9'd281: freqL = `_C5;
			9'd282: freqL = `_C5;		9'd283: freqL = `_C5;
			9'd284: freqL = `bA4;		9'd285: freqL = `bA4;
			9'd286: freqL = `bA4;		9'd287: freqL = `bA4;
			9'd288: freqL = `bA4;		9'd289: freqL = `bA4;
			9'd290: freqL = `bA4;		9'd291: freqL = `bA4;
			9'd292: freqL = `bA4;		9'd293: freqL = `bA4;
			9'd294: freqL = `bA4;		9'd295: freqL = `bA4;
			9'd296: freqL = `_G4;		9'd297: freqL = `_G4;
			9'd298: freqL = `_G4;		9'd299: freqL = `_G4;
			9'd300: freqL = `_G4;		9'd301: freqL = `_G4;
			9'd302: freqL = `_G4;		9'd303: freqL = `_G4;
			9'd304: freqL = `_F4;		9'd305: freqL = `_F4;
			9'd306: freqL = `_F4;		9'd307: freqL = `_F4;
			9'd308: freqL = `_F4;		9'd309: freqL = `_F4;
			9'd310: freqL = `_F4;		9'd311: freqL = `_F4;
			9'd312: freqL = `_D5;		9'd313: freqL = `_D5;
			9'd314: freqL = `_D5;		9'd315: freqL = `_D5;
			9'd316: freqL = `_D5;		9'd317: freqL = `_D5;
			9'd318: freqL = `_D5;		9'd319: freqL = `_D5;
			// --- Measure 6 ---
			9'd320: freqL = `_C5;		9'd321: freqL = `_C5;
			9'd322: freqL = `_C5;		9'd323: freqL = `_C5;
			9'd324: freqL = `_C5;		9'd325: freqL = `_C5;
			9'd326: freqL = `_C5;		9'd327: freqL = `_C5;
			9'd328: freqL = `bB4;		9'd329: freqL = `bB4;
			9'd330: freqL = `bB4;		9'd331: freqL = `bB4;
			9'd332: freqL = `bB4;		9'd333: freqL = `bB4;
			9'd334: freqL = `bB4;		9'd335: freqL = `sil;
			9'd336: freqL = `bB4;		9'd337: freqL = `bB4;
			9'd338: freqL = `bB4;		9'd339: freqL = `bB4;
			9'd340: freqL = `bB4;		9'd341: freqL = `bB4;
			9'd342: freqL = `bB4;		9'd343: freqL = `bB4;
			9'd344: freqL = `_C5;		9'd345: freqL = `_C5;
			9'd346: freqL = `_C5;		9'd347: freqL = `_C5;
			9'd348: freqL = `_C5;		9'd349: freqL = `_C5;
			9'd350: freqL = `_C5;		9'd351: freqL = `_C5;
			9'd352: freqL = `_D5;		9'd353: freqL = `_D5;
			9'd354: freqL = `_D5;		9'd355: freqL = `_D5;
			9'd356: freqL = `_D5;		9'd357: freqL = `_D5;
			9'd358: freqL = `_D5;		9'd359: freqL = `_D5;
			9'd360: freqL = `bE5;		9'd361: freqL = `bE5;
			9'd362: freqL = `bE5;		9'd363: freqL = `bE5;
			9'd364: freqL = `bE5;		9'd365: freqL = `bE5;
			9'd366: freqL = `bE5;		9'd367: freqL = `bE5;
			9'd368: freqL = `bE5;		9'd369: freqL = `bE5;
			9'd370: freqL = `bE5;		9'd371: freqL = `bE5;
			9'd372: freqL = `bE5;		9'd373: freqL = `bE5;
			9'd374: freqL = `bE5;		9'd375: freqL = `bE5;
			9'd376: freqL = `_G4;		9'd377: freqL = `_G4;
			9'd378: freqL = `_G4;		9'd379: freqL = `_G4;
			9'd380: freqL = `_G4;		9'd381: freqL = `_G4;
			9'd382: freqL = `_G4;		9'd383: freqL = `sil;
			// --- Measure 7 ---
			9'd384: freqL = `_G4;		9'd385: freqL = `_G4;
			9'd386: freqL = `_G4;		9'd387: freqL = `_G4;
			9'd388: freqL = `_G4;		9'd389: freqL = `_G4;
			9'd390: freqL = `_G4;		9'd391: freqL = `_G4;
			9'd392: freqL = `_F4;		9'd393: freqL = `_F4;
			9'd394: freqL = `_F4;		9'd395: freqL = `_F4;
			9'd396: freqL = `_F4;		9'd397: freqL = `_F4;
			9'd398: freqL = `_F4;		9'd399: freqL = `_F4;
			9'd400: freqL = `bE4;		9'd401: freqL = `bE4;
			9'd402: freqL = `bE4;		9'd403: freqL = `bE4;
			9'd404: freqL = `bE4;		9'd405: freqL = `bE4;
			9'd406: freqL = `bE4;		9'd407: freqL = `bE4;
			9'd408: freqL = `bE4;		9'd409: freqL = `bE4;
			9'd410: freqL = `bE4;		9'd411: freqL = `bE4;
			9'd412: freqL = `bE4;		9'd413: freqL = `bE4;
			9'd414: freqL = `bE4;		9'd415: freqL = `bE4;
			9'd416: freqL = `bE4;		9'd417: freqL = `bE4;
			9'd418: freqL = `bE4;		9'd419: freqL = `bE4;
			9'd420: freqL = `bE4;		9'd421: freqL = `bE4;
			9'd422: freqL = `bE4;		9'd423: freqL = `bE4;
			9'd424: freqL = `bE4;		9'd425: freqL = `bE4;
			9'd426: freqL = `bE4;		9'd427: freqL = `bE4;
			9'd428: freqL = `bE4;		9'd429: freqL = `bE4;
			9'd430: freqL = `bE4;		9'd431: freqL = `bE4;
			9'd432: freqL = `_G4;		9'd433: freqL = `_G4;
			9'd434: freqL = `_G4;		9'd435: freqL = `_G4;
			9'd436: freqL = `_G4;		9'd437: freqL = `_G4;
			9'd438: freqL = `_G4;		9'd439: freqL = `_G4;
			9'd440: freqL = `_G5;		9'd441: freqL = `_G5;
			9'd442: freqL = `_G5;		9'd443: freqL = `_G5;
			9'd444: freqL = `_G5;		9'd445: freqL = `_G5;
			9'd446: freqL = `_G5;		9'd447: freqL = `_G5;
			// --- Measure 8 ---
			9'd448: freqL = `_F5;		9'd449: freqL = `_F5;
			9'd450: freqL = `_F5;		9'd451: freqL = `_F5;
			9'd452: freqL = `_F5;		9'd453: freqL = `_F5;
			9'd454: freqL = `_F5;		9'd455: freqL = `_F5;
			9'd456: freqL = `_D5;		9'd457: freqL = `_D5;
			9'd458: freqL = `_D5;		9'd459: freqL = `_D5;
			9'd460: freqL = `_D5;		9'd461: freqL = `_D5;
			9'd462: freqL = `_D5;		9'd463: freqL = `_D5;
			9'd464: freqL = `_D5;		9'd465: freqL = `_D5;
			9'd466: freqL = `_D5;		9'd467: freqL = `_D5;
			9'd468: freqL = `_D5;		9'd469: freqL = `_D5;
			9'd470: freqL = `_D5;		9'd471: freqL = `_D5;
			9'd472: freqL = `_D5;		9'd473: freqL = `_D5;
			9'd474: freqL = `_D5;		9'd475: freqL = `_D5;
			9'd476: freqL = `_D5;		9'd477: freqL = `_D5;
			9'd478: freqL = `_D5;		9'd479: freqL = `_D5;
			9'd480: freqL = `_D5;		9'd481: freqL = `_D5;
			9'd482: freqL = `_D5;		9'd483: freqL = `_D5;
			9'd484: freqL = `_D5;		9'd485: freqL = `_D5;
			9'd486: freqL = `_D5;		9'd487: freqL = `_D5;
			9'd488: freqL = `_D5;		9'd489: freqL = `_D5;
			9'd490: freqL = `_D5;		9'd491: freqL = `_D5;
			9'd492: freqL = `_D5;		9'd493: freqL = `_D5;
			9'd494: freqL = `_D5;		9'd495: freqL = `_D5;
			9'd496: freqL = `_D5;		9'd497: freqL = `_D5;
			9'd498: freqL = `_D5;		9'd499: freqL = `_D5;
			9'd500: freqL = `_D5;		9'd501: freqL = `_D5;
			9'd502: freqL = `_D5;		9'd503: freqL = `_D5;
			9'd504: freqL = `sil;		9'd505: freqL = `sil;
			9'd506: freqL = `sil;		9'd507: freqL = `sil;
			9'd508: freqL = `sil;		9'd509: freqL = `sil;
			9'd510: freqL = `sil;		9'd511: freqL = `sil;
		endcase
	end

	// freqR
	always @* begin
		case(beat)
			// --- Measure 1 ---
			9'd0: freqR = `sil;		9'd1: freqR = `sil;
			9'd2: freqR = `sil;		9'd3: freqR = `sil;
			9'd4: freqR = `sil;		9'd5: freqR = `sil;
			9'd6: freqR = `sil;		9'd7: freqR = `sil;
			9'd8: freqR = `sil;		9'd9: freqR = `sil;
			9'd10: freqR = `sil;		9'd11: freqR = `sil;
			9'd12: freqR = `sil;		9'd13: freqR = `sil;
			9'd14: freqR = `sil;		9'd15: freqR = `sil;
			9'd16: freqR = `bA3;		9'd17: freqR = `bA3;
			9'd18: freqR = `bA3;		9'd19: freqR = `bA3;
			9'd20: freqR = `bA3;		9'd21: freqR = `bA3;
			9'd22: freqR = `bA3;		9'd23: freqR = `bA3;
			9'd24: freqR = `bA3;		9'd25: freqR = `bA3;
			9'd26: freqR = `bA3;		9'd27: freqR = `bA3;
			9'd28: freqR = `bA3;		9'd29: freqR = `bA3;
			9'd30: freqR = `bA3;		9'd31: freqR = `bA3;
			9'd32: freqR = `bA3;		9'd33: freqR = `bA3;
			9'd34: freqR = `bA3;		9'd35: freqR = `bA3;
			9'd36: freqR = `bA3;		9'd37: freqR = `bA3;
			9'd38: freqR = `bA3;		9'd39: freqR = `bA3;
			9'd40: freqR = `bA3;		9'd41: freqR = `bA3;
			9'd42: freqR = `bA3;		9'd43: freqR = `bA3;
			9'd44: freqR = `bA3;		9'd45: freqR = `bA3;
			9'd46: freqR = `bA3;		9'd47: freqR = `bA3;
			9'd48: freqR = `bB3;		9'd49: freqR = `bB3;
			9'd50: freqR = `bB3;		9'd51: freqR = `bB3;
			9'd52: freqR = `bB3;		9'd53: freqR = `bB3;
			9'd54: freqR = `bB3;		9'd55: freqR = `bB3;
			9'd56: freqR = `bB3;		9'd57: freqR = `bB3;
			9'd58: freqR = `bB3;		9'd59: freqR = `bB3;
			9'd60: freqR = `bB3;		9'd61: freqR = `bB3;
			9'd62: freqR = `bB3;		9'd63: freqR = `sil;
			// --- Measure 2 ---
			9'd64: freqR = `bB3;		9'd65: freqR = `bB3;
			9'd66: freqR = `bB3;		9'd67: freqR = `bB3;
			9'd68: freqR = `bB3;		9'd69: freqR = `bB3;
			9'd70: freqR = `bB3;		9'd71: freqR = `bB3;
			9'd72: freqR = `bB3;		9'd73: freqR = `bB3;
			9'd74: freqR = `bB3;		9'd75: freqR = `bB3;
			9'd76: freqR = `bB3;		9'd77: freqR = `bB3;
			9'd78: freqR = `bB3;		9'd79: freqR = `bB3;
			9'd80: freqR = `_G3;		9'd81: freqR = `_G3;
			9'd82: freqR = `_G3;		9'd83: freqR = `_G3;
			9'd84: freqR = `_G3;		9'd85: freqR = `_G3;
			9'd86: freqR = `_G3;		9'd87: freqR = `_G3;
			9'd88: freqR = `_G3;		9'd89: freqR = `_G3;
			9'd90: freqR = `_G3;		9'd91: freqR = `_G3;
			9'd92: freqR = `_G3;		9'd93: freqR = `_G3;
			9'd94: freqR = `_G3;		9'd95: freqR = `_G3;
			9'd96: freqR = `_G3;		9'd97: freqR = `_G3;
			9'd98: freqR = `_G3;		9'd99: freqR = `_G3;
			9'd100: freqR = `_G3;		9'd101: freqR = `_G3;
			9'd102: freqR = `_G3;		9'd103: freqR = `_G3;
			9'd104: freqR = `_G3;		9'd105: freqR = `_G3;
			9'd106: freqR = `_G3;		9'd107: freqR = `_G3;
			9'd108: freqR = `_G3;		9'd109: freqR = `_G3;
			9'd110: freqR = `_G3;		9'd111: freqR = `_G3;
			9'd112: freqR = `_C4;		9'd113: freqR = `_C4;
			9'd114: freqR = `_C4;		9'd115: freqR = `_C4;
			9'd116: freqR = `_C4;		9'd117: freqR = `_C4;
			9'd118: freqR = `_C4;		9'd119: freqR = `_C4;
			9'd120: freqR = `_C4;		9'd121: freqR = `_C4;
			9'd122: freqR = `_C4;		9'd123: freqR = `_C4;
			9'd124: freqR = `_C4;		9'd125: freqR = `_C4;
			9'd126: freqR = `_C4;		9'd127: freqR = `sil;
			// --- Measure 3 ---
			9'd128: freqR = `_C4;		9'd129: freqR = `_C4;
			9'd130: freqR = `_C4;		9'd131: freqR = `_C4;
			9'd132: freqR = `_C4;		9'd133: freqR = `_C4;
			9'd134: freqR = `_C4;		9'd135: freqR = `_C4;
			9'd136: freqR = `_C4;		9'd137: freqR = `_C4;
			9'd138: freqR = `_C4;		9'd139: freqR = `_C4;
			9'd140: freqR = `_C4;		9'd141: freqR = `_C4;
			9'd142: freqR = `_C4;		9'd143: freqR = `_C4;
			9'd144: freqR = `bA3;		9'd145: freqR = `bA3;
			9'd146: freqR = `bA3;		9'd147: freqR = `bA3;
			9'd148: freqR = `bA3;		9'd149: freqR = `bA3;
			9'd150: freqR = `bA3;		9'd151: freqR = `bA3;
			9'd152: freqR = `bA3;		9'd153: freqR = `bA3;
			9'd154: freqR = `bA3;		9'd155: freqR = `bA3;
			9'd156: freqR = `bA3;		9'd157: freqR = `bA3;
			9'd158: freqR = `bA3;		9'd159: freqR = `bA3;
			9'd160: freqR = `bA3;		9'd161: freqR = `bA3;
			9'd162: freqR = `bA3;		9'd163: freqR = `bA3;
			9'd164: freqR = `bA3;		9'd165: freqR = `bA3;
			9'd166: freqR = `bA3;		9'd167: freqR = `bA3;
			9'd168: freqR = `bA3;		9'd169: freqR = `bA3;
			9'd170: freqR = `bA3;		9'd171: freqR = `bA3;
			9'd172: freqR = `bA3;		9'd173: freqR = `bA3;
			9'd174: freqR = `bA3;		9'd175: freqR = `bA3;
			9'd176: freqR = `_G3;		9'd177: freqR = `_G3;
			9'd178: freqR = `_G3;		9'd179: freqR = `_G3;
			9'd180: freqR = `_G3;		9'd181: freqR = `_G3;
			9'd182: freqR = `_G3;		9'd183: freqR = `_G3;
			9'd184: freqR = `_G3;		9'd185: freqR = `_G3;
			9'd186: freqR = `_G3;		9'd187: freqR = `_G3;
			9'd188: freqR = `_G3;		9'd189: freqR = `_G3;
			9'd190: freqR = `_G3;		9'd191: freqR = `sil;
			// --- Measure 4 ---
			9'd192: freqR = `_G3;		9'd193: freqR = `_G3;
			9'd194: freqR = `_G3;		9'd195: freqR = `_G3;
			9'd196: freqR = `_G3;		9'd197: freqR = `_G3;
			9'd198: freqR = `_G3;		9'd199: freqR = `_G3;
			9'd200: freqR = `_G3;		9'd201: freqR = `_G3;
			9'd202: freqR = `_G3;		9'd203: freqR = `_G3;
			9'd204: freqR = `_G3;		9'd205: freqR = `_G3;
			9'd206: freqR = `_G3;		9'd207: freqR = `_G3;
			9'd208: freqR = `_C4;		9'd209: freqR = `_C4;
			9'd210: freqR = `_C4;		9'd211: freqR = `_C4;
			9'd212: freqR = `_C4;		9'd213: freqR = `_C4;
			9'd214: freqR = `_C4;		9'd215: freqR = `_C4;
			9'd216: freqR = `_C4;		9'd217: freqR = `_C4;
			9'd218: freqR = `_C4;		9'd219: freqR = `_C4;
			9'd220: freqR = `_C4;		9'd221: freqR = `_C4;
			9'd222: freqR = `_C4;		9'd223: freqR = `_C4;
			9'd224: freqR = `_C4;		9'd225: freqR = `_C4;
			9'd226: freqR = `_C4;		9'd227: freqR = `_C4;
			9'd228: freqR = `_C4;		9'd229: freqR = `_C4;
			9'd230: freqR = `_C4;		9'd231: freqR = `_C4;
			9'd232: freqR = `_C4;		9'd233: freqR = `_C4;
			9'd234: freqR = `_C4;		9'd235: freqR = `_C4;
			9'd236: freqR = `_C4;		9'd237: freqR = `_C4;
			9'd238: freqR = `_C4;		9'd239: freqR = `_C4;
			9'd240: freqR = `_G3;		9'd241: freqR = `_G3;
			9'd242: freqR = `_G3;		9'd243: freqR = `_G3;
			9'd244: freqR = `_G3;		9'd245: freqR = `_G3;
			9'd246: freqR = `_G3;		9'd247: freqR = `_G3;
			9'd248: freqR = `_G3;		9'd249: freqR = `_G3;
			9'd250: freqR = `_G3;		9'd251: freqR = `_G3;
			9'd252: freqR = `_G3;		9'd253: freqR = `_G3;
			9'd254: freqR = `_G3;		9'd255: freqR = `_G3;
			// --- Measure 5 ---
			9'd256: freqR = `sil;		9'd257: freqR = `sil;
			9'd258: freqR = `sil;		9'd259: freqR = `sil;
			9'd260: freqR = `sil;		9'd261: freqR = `sil;
			9'd262: freqR = `sil;		9'd263: freqR = `sil;
			9'd264: freqR = `sil;		9'd265: freqR = `sil;
			9'd266: freqR = `sil;		9'd267: freqR = `sil;
			9'd268: freqR = `sil;		9'd269: freqR = `sil;
			9'd270: freqR = `sil;		9'd271: freqR = `sil;
			9'd272: freqR = `bA2;		9'd273: freqR = `bA2;
			9'd274: freqR = `bA2;		9'd275: freqR = `bA2;
			9'd276: freqR = `bA2;		9'd277: freqR = `bA2;
			9'd278: freqR = `bA2;		9'd279: freqR = `bA2;
			9'd280: freqR = `bE3;		9'd281: freqR = `bE3;
			9'd282: freqR = `bE3;		9'd283: freqR = `bE3;
			9'd284: freqR = `bE3;		9'd285: freqR = `bE3;
			9'd286: freqR = `bE3;		9'd287: freqR = `bE3;
			9'd288: freqR = `bA3;		9'd289: freqR = `bA3;
			9'd290: freqR = `bA3;		9'd291: freqR = `bA3;
			9'd292: freqR = `bA3;		9'd293: freqR = `bA3;
			9'd294: freqR = `bA3;		9'd295: freqR = `bA3;
			9'd296: freqR = `bE3;		9'd297: freqR = `bE3;
			9'd298: freqR = `bE3;		9'd299: freqR = `bE3;
			9'd300: freqR = `bE3;		9'd301: freqR = `bE3;
			9'd302: freqR = `bE3;		9'd303: freqR = `bE3;
			9'd304: freqR = `bB2;		9'd305: freqR = `bB2;
			9'd306: freqR = `bB2;		9'd307: freqR = `bB2;
			9'd308: freqR = `bB2;		9'd309: freqR = `bB2;
			9'd310: freqR = `bB2;		9'd311: freqR = `bB2;
			9'd312: freqR = `_F3;		9'd313: freqR = `_F3;
			9'd314: freqR = `_F3;		9'd315: freqR = `_F3;
			9'd316: freqR = `_F3;		9'd317: freqR = `_F3;
			9'd318: freqR = `_F3;		9'd319: freqR = `_F3;
			// --- Measure 6 ---
			9'd320: freqR = `bB3;		9'd321: freqR = `bB3;
			9'd322: freqR = `bB3;		9'd323: freqR = `bB3;
			9'd324: freqR = `bB3;		9'd325: freqR = `bB3;
			9'd326: freqR = `bB3;		9'd327: freqR = `bB3;
			9'd328: freqR = `_F3;		9'd329: freqR = `_F3;
			9'd330: freqR = `_F3;		9'd331: freqR = `_F3;
			9'd332: freqR = `_F3;		9'd333: freqR = `_F3;
			9'd334: freqR = `_F3;		9'd335: freqR = `_F3;
			9'd336: freqR = `_G2;		9'd337: freqR = `_G2;
			9'd338: freqR = `_G2;		9'd339: freqR = `_G2;
			9'd340: freqR = `_G2;		9'd341: freqR = `_G2;
			9'd342: freqR = `_G2;		9'd343: freqR = `_G2;
			9'd344: freqR = `_D3;		9'd345: freqR = `_D3;
			9'd346: freqR = `_D3;		9'd347: freqR = `_D3;
			9'd348: freqR = `_D3;		9'd349: freqR = `_D3;
			9'd350: freqR = `_D3;		9'd351: freqR = `_D3;
			9'd352: freqR = `_G3;		9'd353: freqR = `_G3;
			9'd354: freqR = `_G3;		9'd355: freqR = `_G3;
			9'd356: freqR = `_G3;		9'd357: freqR = `_G3;
			9'd358: freqR = `_G3;		9'd359: freqR = `_G3;
			9'd360: freqR = `_D3;		9'd361: freqR = `_D3;
			9'd362: freqR = `_D3;		9'd363: freqR = `_D3;
			9'd364: freqR = `_D3;		9'd365: freqR = `_D3;
			9'd366: freqR = `_D3;		9'd367: freqR = `_D3;
			9'd368: freqR = `_C3;		9'd369: freqR = `_C3;
			9'd370: freqR = `_C3;		9'd371: freqR = `_C3;
			9'd372: freqR = `_C3;		9'd373: freqR = `_C3;
			9'd374: freqR = `_C3;		9'd375: freqR = `_C3;
			9'd376: freqR = `_G3;		9'd377: freqR = `_G3;
			9'd378: freqR = `_G3;		9'd379: freqR = `_G3;
			9'd380: freqR = `_G3;		9'd381: freqR = `_G3;
			9'd382: freqR = `_G3;		9'd383: freqR = `_G3;
			// --- Measure 7 ---
			9'd384: freqR = `bE4;		9'd385: freqR = `bE4;
			9'd386: freqR = `bE4;		9'd387: freqR = `bE4;
			9'd388: freqR = `bE4;		9'd389: freqR = `bE4;
			9'd390: freqR = `bE4;		9'd391: freqR = `bE4;
			9'd392: freqR = `_G3;		9'd393: freqR = `_G3;
			9'd394: freqR = `_G3;		9'd395: freqR = `_G3;
			9'd396: freqR = `_G3;		9'd397: freqR = `_G3;
			9'd398: freqR = `_G3;		9'd399: freqR = `_G3;
			9'd400: freqR = `bA3;		9'd401: freqR = `bA3;
			9'd402: freqR = `bA3;		9'd403: freqR = `bA3;
			9'd404: freqR = `bA3;		9'd405: freqR = `bA3;
			9'd406: freqR = `bA3;		9'd407: freqR = `bA3;
			9'd408: freqR = `bA3;		9'd409: freqR = `bA3;
			9'd410: freqR = `bA3;		9'd411: freqR = `bA3;
			9'd412: freqR = `bA3;		9'd413: freqR = `bA3;
			9'd414: freqR = `bA3;		9'd415: freqR = `bA3;
			9'd416: freqR = `bA3;		9'd417: freqR = `bA3;
			9'd418: freqR = `bA3;		9'd419: freqR = `bA3;
			9'd420: freqR = `bA3;		9'd421: freqR = `bA3;
			9'd422: freqR = `bA3;		9'd423: freqR = `bA3;
			9'd424: freqR = `bA3;		9'd425: freqR = `bA3;
			9'd426: freqR = `bA3;		9'd427: freqR = `bA3;
			9'd428: freqR = `bA3;		9'd429: freqR = `bA3;
			9'd430: freqR = `bA3;		9'd431: freqR = `bA3;
			9'd432: freqR = `_G3;		9'd433: freqR = `_G3;
			9'd434: freqR = `_G3;		9'd435: freqR = `_G3;
			9'd436: freqR = `_G3;		9'd437: freqR = `_G3;
			9'd438: freqR = `_G3;		9'd439: freqR = `_G3;
			9'd440: freqR = `_G3;		9'd441: freqR = `_G3;
			9'd442: freqR = `_G3;		9'd443: freqR = `_G3;
			9'd444: freqR = `_G3;		9'd445: freqR = `_G3;
			9'd446: freqR = `_G3;		9'd447: freqR = `_G3;
			// --- Measure 8 ---
			9'd448: freqR = `_D3;		9'd449: freqR = `_D3;
			9'd450: freqR = `_D3;		9'd451: freqR = `_D3;
			9'd452: freqR = `_D3;		9'd453: freqR = `_D3;
			9'd454: freqR = `_D3;		9'd455: freqR = `_D3;
			9'd456: freqR = `_D3;		9'd457: freqR = `_D3;
			9'd458: freqR = `_D3;		9'd459: freqR = `_D3;
			9'd460: freqR = `_D3;		9'd461: freqR = `_D3;
			9'd462: freqR = `_D3;		9'd463: freqR = `_D3;
			9'd464: freqR = `_D3;		9'd465: freqR = `_D3;
			9'd466: freqR = `_D3;		9'd467: freqR = `_D3;
			9'd468: freqR = `_D3;		9'd469: freqR = `_D3;
			9'd470: freqR = `_D3;		9'd471: freqR = `_D3;
			9'd472: freqR = `_D3;		9'd473: freqR = `_D3;
			9'd474: freqR = `_D3;		9'd475: freqR = `_D3;
			9'd476: freqR = `_D3;		9'd477: freqR = `_D3;
			9'd478: freqR = `_D3;		9'd479: freqR = `_D3;
			9'd480: freqR = `_D3;		9'd481: freqR = `_D3;
			9'd482: freqR = `_D3;		9'd483: freqR = `_D3;
			9'd484: freqR = `_D3;		9'd485: freqR = `_D3;
			9'd486: freqR = `_D3;		9'd487: freqR = `_D3;
			9'd488: freqR = `_D3;		9'd489: freqR = `_D3;
			9'd490: freqR = `_D3;		9'd491: freqR = `_D3;
			9'd492: freqR = `_D3;		9'd493: freqR = `_D3;
			9'd494: freqR = `_D3;		9'd495: freqR = `_D3;
			9'd496: freqR = `sil;		9'd497: freqR = `sil;
			9'd498: freqR = `sil;		9'd499: freqR = `sil;
			9'd500: freqR = `sil;		9'd501: freqR = `sil;
			9'd502: freqR = `sil;		9'd503: freqR = `sil;
			9'd504: freqR = `sil;		9'd505: freqR = `sil;
			9'd506: freqR = `sil;		9'd507: freqR = `sil;
			9'd508: freqR = `sil;		9'd509: freqR = `sil;
			9'd510: freqR = `sil;		9'd511: freqR = `sil;
		endcase
	end

endmodule

module vol_gen(
    input clk,
    input rst,
    input mute,
    input volUP,
    input volDOWN,
    output wire [2:0] volume
    );
    reg [2:0] vol, next_vol;

    // volume
    assign volume = mute?3'd0:vol;

    // vol
    always @(posedge clk, posedge rst) begin
        if(rst) vol <= 3'd3;
        else vol <= next_vol;
    end

    // next_vol
    always @* begin
        next_vol = vol;
        if(volUP && vol!=3'd5) next_vol = vol+3'd1;
        else if(volDOWN && vol!=3'd1) next_vol = vol-3'd1;
    end

endmodule