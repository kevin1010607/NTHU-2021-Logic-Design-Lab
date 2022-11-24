`define silence   32'd50000000

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
    output [15:0] _led; 
    output audio_mclk; 
    output audio_lrck; 
    output audio_sck; 
    output audio_sdin; 
    output [6:0] DISPLAY; 
    output [3:0] DIGIT; 
    
    // Modify these
    assign _led = 16'b1110_0000_0001_1111;
    assign DIGIT = 4'b0000;
    assign DISPLAY = 7'b0111111;

    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;

    wire [11:0] ibeatNum;               // Beat counter
    wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3

    // clkDiv22
    wire clkDiv22;
    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clkDiv22));    // for keyboard and audio

    // Player Control
    // [in]  reset, clock, _play, _slow, _music, and _mode
    // [out] beat number
    player_control #(.LEN(128)) playerCtrl_00 ( 
        .clk(clkDiv22),
        .reset(rst),
        ._play(1'b1),
        ._slow(1'b0), 
        ._mode(1'b0),
        .ibeat(ibeatNum)
    );

    // Music module
    // [in]  beat number and en
    // [out] left & right raw frequency
    music_example music_00 (
        .ibeatNum(ibeatNum),
        .en(1'b1),
        .toneL(freqL),
        .toneR(freqR)
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
        .volume(3'b000),
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
