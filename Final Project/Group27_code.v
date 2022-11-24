module Bird(
    input clk,
    input rst,
    input up,
    input over,
    input [9:0] process_state,
    input turn_ok,
    inout PS2_CLK,
    inout PS2_DATA,
    output reg [9:0] bird_y,
    output reg [9:0] state,
    output [511:0] key_down,
    output been_ready
);

reg [31:0] move_up_cnt, next_move_up_cnt;
reg [31:0] move_down_cnt, next_move_down_cnt;
reg [31:0] state_cnt, next_state_cnt;
reg [9:0] next_state;
reg [9:0] next_bird_y;
wire [8:0]last_change;

parameter UP_SEC = 1024*512; //數字越小，鳥掉落越快 
parameter DOWN_SEC = 1024*1024; //數字越小，鳥掉落越快 
parameter STATE_SEC = 1024*1024*20; // 數字越大，鳥上升時間越長

// bird state
parameter UP = 0;
parameter DOWN = 1;
parameter FIX = 2;
parameter TURN = 3;
parameter FALL = 4;
parameter DEAD = 5;

// process state
parameter IDLE = 8;
parameter STAGE1 = 9; // 管子不動
parameter REMOVE_TUBE_HARP = 10;
parameter MOVE_TUBE4_HARP = 11;
parameter HARP_FIGHT = 12;
parameter REMOVE_TUBE4_HARP = 13;

parameter STAGE2 = 14; // 管子移動
parameter STAGE3 = 15; // 管子不動
parameter REMOVE_TUBE = 16;
parameter MOVE_TUBE4 = 17;
parameter BOSS_FIGHT = 18;
parameter REMOVE_TUBE4 = 19;
parameter MOVE_NEST = 20;
parameter WIN = 21;
parameter CLEAR = 22;


// tube state
parameter LEFT = 27;
parameter RIGHT = 28;
parameter PAUSE = 29;

// monkey state
parameter MOVE_0 = 30; // 上升
parameter MOVE_1 = 31; // ready
parameter MOVE_2 = 32;
parameter MOVE_3 = 33;
parameter MOVE_4 = 34;
parameter MOVE_5 = 35;
parameter MOVE_6 = 36;
parameter MOVE_7 = 37;
parameter MOVE_8 = 38;
parameter MOVE_9 = 39;
parameter MOVE_10 = 40; // 跌倒
parameter MONKEY_FALL = 41;
parameter MONKEY_DEAD= 42;

// harp state
parameter HARP_LEAVE = 45;
parameter HARP_DEAD = 46;


KeyboardDecoder key_de(key_down, last_change, been_ready, PS2_DATA, PS2_CLK, rst, clk);

always @(posedge clk, posedge rst) begin
    if(rst)begin //初始化鳥的位置
        bird_y <= 240; //480/2=240 
        state <= FIX;
        move_up_cnt <= 0;
        move_down_cnt <= 0;
        state_cnt <= 0;
    end
    else begin // 如果遊戲還沒結束
        bird_y <= next_bird_y;
        state <= next_state;
        move_up_cnt <= next_move_up_cnt;
        move_down_cnt <= next_move_down_cnt;
        state_cnt <= next_state_cnt;
    end
end


always @(*) begin
    next_bird_y = bird_y;
    next_move_up_cnt = 0;
    next_move_down_cnt = 0;
    case(state)
        FIX:begin
            next_bird_y = bird_y;
            next_move_up_cnt = 0;
            next_move_down_cnt = 0;
        end
        UP:begin
            next_move_down_cnt = 0;
            if(bird_y <= 20)begin
               next_move_down_cnt = 0;
               next_bird_y = bird_y;
            end
            else if(move_up_cnt == UP_SEC)begin
                next_move_up_cnt = 0;
                if(bird_y > 10)begin
                    next_bird_y = bird_y - 1;
                end
                else begin
                    next_bird_y = bird_y;
                end
                
            end
            else begin
                next_move_up_cnt = move_up_cnt + 1;
                next_bird_y = bird_y;
            end
        end
        DOWN:begin
           next_move_up_cnt = 0;
           if(bird_y >= 460)begin
               next_move_down_cnt = 0;
               next_bird_y = bird_y;
           end
           else if(move_down_cnt == DOWN_SEC)begin
                next_move_down_cnt = 0;
                next_bird_y = bird_y + 1;
            end
            else begin
                next_move_down_cnt = move_down_cnt + 1;
                next_bird_y = bird_y;
            end
        end
        TURN:begin
            
        end
        FALL:begin
            next_move_up_cnt = 0;
           if(move_down_cnt == DOWN_SEC)begin
                next_move_down_cnt = 0;
                next_bird_y = bird_y + 1;
            end
            else begin
                next_move_down_cnt = move_down_cnt + 1;
                next_bird_y = bird_y;
            end
        end
        DEAD:begin
            if(process_state == IDLE)begin
                next_bird_y = 240;
                next_move_up_cnt = 0;
                next_move_down_cnt = 0;
            end
            
        end
        default:begin
            next_bird_y = bird_y;
            next_move_up_cnt = 0;
            next_move_down_cnt = 0;
        end

    endcase
end


always @(*) begin
    next_state = state;
    next_state_cnt = 0;
    case(state)
        FIX:begin
            if(process_state != MOVE_NEST && process_state != WIN && been_ready && key_down[9'b000101001] == 1'b1)begin
                next_state = UP;
                next_state_cnt = 0;        
            end
        end

        UP:begin
            if(over == 1)begin
                next_state = TURN;
            end
            else if(process_state == MOVE_NEST)begin
                if(bird_y == 240)begin
                    next_state = FIX;
                end
                else if(bird_y > 240)begin
                    next_state = UP;
                end
                else begin
                    next_state = DOWN;
                end
            end
            else if(been_ready && key_down[9'b000101001] == 1'b1)begin
                next_state_cnt = 0;
            end
            else if(state_cnt == STATE_SEC)begin
                next_state = DOWN;
            end
            else begin
                next_state_cnt = state_cnt + 1;
            end
        end
        DOWN:begin
            if(over == 1)begin
                next_state = TURN;
            end
            else if(process_state == MOVE_NEST)begin
                if(bird_y == 240)begin
                    next_state = FIX;
                end
                else if(bird_y < 240)begin
                    next_state = DOWN;
                end
                else begin
                    next_state = UP;
                end
            end
            else if(been_ready && key_down[9'b000101001] == 1'b1)begin
                next_state = UP;
                next_state_cnt = 0;        
            end
        end
        TURN:begin
            if(turn_ok)begin
                next_state = FALL;
            end
        end
        FALL:begin
            if(bird_y+15 > 470)begin
                next_state = DEAD;
            end
        end
        DEAD:begin
            if(process_state == IDLE)begin
                next_state = FIX;
                next_state_cnt = 0;
            end
        end
    endcase
end

endmodule

module Game_disp(
    input clk_tube,
    input clk_wing, // clk_23, only for 揮動翅膀
    input clk_turn, // clk_25, only for turn
    input rst,
    input [9:0] process_state,
    input [9:0] bird_state,
    input [9:0] monkey_state,
    input [9:0] harp_state,
    input [9:0] h_cnt,
    input [9:0] v_cnt,
    input [9:0] bird_y,
    input [31:0] tube1_x,
    input [31:0] tube1_y,
    input [31:0] tube2_x,
    input [31:0] tube2_y,
    input [31:0] tube3_x,
    input [31:0] tube3_y,
    input [31:0] tube4_x, 
    input [31:0] tube4_y,
    input [31:0] tube5_x, 
    input [31:0] tube5_y,
    input [31:0] missle_x, 
    input [31:0] missle_y,
    input [31:0] cloud1_x,
    input [31:0] cloud1_y,
    input [31:0] cloud2_x,
    input [31:0] cloud2_y,
    input [31:0] cloud3_x,
    input [31:0] cloud3_y,
    input [31:0] cloud4_x,
    input [31:0] cloud4_y,
    input [31:0] cloud5_x,
    input [31:0] cloud5_y,
    input [31:0] cloud6_x,
    input [31:0] cloud6_y,
    input [31:0] ghost_x, 
    input [31:0] ghost_y,
    input [31:0] plant_x,
    input [31:0] plant_y,
    input [31:0] spider_x,
    input [31:0] spider_y,
    input [31:0] monkey_x,
    input [31:0] monkey_y,
    input [31:0] banana_x,
    input [31:0] banana_y,
    input [31:0] nest_x,
    input [31:0] nest_y,
    input [31:0] harp_x,
    input [31:0] harp_y,
    input [31:0] ball1_x, 
    input [31:0] ball1_y,
    input [31:0] ball2_x,
    input [31:0] ball2_y,
    input [31:0] ball3_x,
    input [31:0] ball3_y,
    input over,
    input clk_25Mhz,
    output reg [11:0]pixel,
    output reg turn_ok,
    output reg [9:0] bird_x
    );
     
    
    // bird state
parameter UP = 0;
parameter DOWN = 1;
parameter FIX = 2;
parameter TURN = 3;
parameter FALL = 4;
parameter DEAD = 5;

    // process state
    parameter IDLE = 8;
    parameter STAGE1 = 9; // 管子不動
    parameter REMOVE_TUBE_HARP = 10;
    parameter MOVE_TUBE4_HARP = 11;
    parameter HARP_FIGHT = 12;
    parameter REMOVE_TUBE4_HARP = 13;

    parameter STAGE2 = 14; // 管子移動
    parameter STAGE3 = 15; // 管子不動
    parameter REMOVE_TUBE = 16;
    parameter MOVE_TUBE4 = 17;
    parameter BOSS_FIGHT = 18;
    parameter REMOVE_TUBE4 = 19;
    parameter MOVE_NEST = 20;
    parameter WIN = 21;

    
    // tube state
    parameter LEFT = 27;
    parameter RIGHT = 28;
    parameter PAUSE = 29;

    // monkey state
    parameter MOVE_0 = 30; // 上升
    parameter MOVE_1 = 31; // ready
    parameter MOVE_2 = 32;
    parameter MOVE_3 = 33;
    parameter MOVE_4 = 34;
    parameter MOVE_5 = 35;
    parameter MOVE_6 = 36;
    parameter MOVE_7 = 37;
    parameter MOVE_8 = 38;
    parameter MOVE_9 = 39;
    parameter MOVE_10 = 40; // 跌倒
    parameter MONKEY_FALL = 41;
    parameter MONKEY_DEAD= 42;

    // harp state
    parameter HARP_LEAVE = 45;
    parameter HARP_DEAD = 46;


    reg [9:0] next_bird_x;
    always @(posedge clk_tube, posedge rst)begin
        if(rst)begin
            bird_x <= 320;
        end
        else begin
            bird_x <= next_bird_x;
        end
    end

    always @(*) begin
        next_bird_x = bird_x;
        if(process_state == IDLE)begin
            next_bird_x = 320;
        end
        else if(process_state == STAGE1)begin
            if(bird_x > 220)begin
                next_bird_x = bird_x - 1;
            end 
        end
        else if(process_state == MOVE_NEST)begin
            if(bird_y == 240)begin
                if(bird_x < 300)begin
                    next_bird_x = bird_x + 1;
                end
            end
            else begin
                next_bird_x = bird_x;
            end
            
        end
        
    end
    
    
    wire [11:0] garbage; // data in
    wire [11:0] data_out_1, data_out_2, data_out_3, data_out_4, data_out_5, data_out_6, data_out_7, data_out_8, data_out_9, data_out_10;
    wire [11:0] data_out_11, data_out_12, data_out_13, data_out_14, data_out_15, data_out_16, data_out_17, data_out_18, data_out_19, data_out_20; // data out
    wire [11:0] data_out_21, data_out_22, data_out_23, data_out_24, data_out_25, data_out_26, data_out_27, data_out_28, data_out_29, data_out_30;
    wire [11:0] data_out_31, data_out_32, data_out_33, data_out_34, data_out_35, data_out_36, data_out_37, data_out_38, data_out_39, data_out_40;
    wire [11:0] data_out_41, data_out_42, data_out_43, data_out_44, data_out_45, data_out_46, data_out_47, data_out_48, data_out_49, data_out_50;
    wire [11:0] data_out_51;
    reg [9:0] add_1; 
    reg [9:0] add_2, add_4, add_5, add_19, add_20;
    reg [12:0] add_3;
    reg [10:0] add_6;
    reg [9:0] add_7;
    reg [8:0] add_8;
    reg [10:0] add_9;
    reg [8:0] add_10;
    reg [10:0] add_11;
    reg [9:0] add_12;
    reg [10:0] add_13, add_14, add_15, add_16, add_17, add_18, add_36, add_37, add_50, add_51;
    reg [9:0] add_21, add_22;
    reg [10:0] add_23, add_24 ,add_39;
    reg [11:0] add_25, add_26, add_27, add_28, add_29, add_30, add_31, add_32, add_33, add_34;
    reg [8:0] add_35;
    reg [10:0] add_38;
    reg [10:0] add_40, add_41, add_42;
    reg [10:0] add_43, add_44, add_45, add_46;
    reg [7:0] add_47, add_48, add_49;
    reg cnt, next_cnt;
    reg [3:0] turn_cnt, next_turn_cnt; 
    reg next_turn_ok;
    reg [11:0] rgb;


    // 背景圖案 160*120
    bg mem1(.clka(clk_25Mhz), .addra(add_1), .douta(data_out_1), .wea(0), .dina(garbage));
    
    // 遊戲結束圖案 76*76
    over mem3(.clka(clk_25Mhz), .addra(add_3), .douta(data_out_3), .wea(0), .dina(garbage));

    // 鳥的圖案 30*30，揮動翅膀(1) 
    bird1 mem2(.clka(clk_25Mhz), .addra(add_2), .douta(data_out_2), .wea(0), .dina(garbage));

    // 鳥的圖案 30*30，揮動翅膀(2) 
    bird2 mem4(.clka(clk_25Mhz), .addra(add_4), .douta(data_out_4), .wea(0), .dina(garbage));

    // 鳥的圖案 30*30，鳥往上飛 
    fly mem5(.clka(clk_25Mhz), .addra(add_5), .douta(data_out_5), .wea(0), .dina(garbage));

    // 飛彈的圖案 40*30 
    missle mem6(.clka(clk_25Mhz), .addra(add_6), .douta(data_out_6), .wea(0), .dina(garbage));

    
    // 兩朵雲 40*20 (cloud1)
    cloud1 mem7(.clka(clk_25Mhz), .addra(add_7), .douta(data_out_7), .wea(0), .dina(garbage));

    // 一朵雲 20*20 (cloud2)
    cloud2 mem8(.clka(clk_25Mhz), .addra(add_8), .douta(data_out_8), .wea(0), .dina(garbage));
    
    // 三朵雲 60*20 (cloud3)
    cloud3 mem9(.clka(clk_25Mhz), .addra(add_9), .douta(data_out_9), .wea(0), .dina(garbage));

    // 一朵雲 20*20 (cloud4)
    cloud4 mem10(.clka(clk_25Mhz), .addra(add_10), .douta(data_out_10), .wea(0), .dina(garbage));

    // 三朵雲 60*20 (cloud5)
    cloud5 mem11(.clka(clk_25Mhz), .addra(add_11), .douta(data_out_11), .wea(0), .dina(garbage));

    // 兩朵雲 40*20 (cloud6)
    cloud6 mem12(.clka(clk_25Mhz), .addra(add_12), .douta(data_out_12), .wea(0), .dina(garbage));

    // 下排管子 60*20 第32排往下重複 (1)
    down_pipe mem13(.clka(clk_25Mhz), .addra(add_13), .douta(data_out_13), .wea(0), .dina(garbage));

    // 下排管子 60*20 第32排往下重複 (2)
    down_pipe mem14(.clka(clk_25Mhz), .addra(add_14), .douta(data_out_14), .wea(0), .dina(garbage));

    // 下排管子 60*20 第32排往下重複 (3)
    down_pipe mem15(.clka(clk_25Mhz), .addra(add_15), .douta(data_out_15), .wea(0), .dina(garbage));

    // 下排管子 60*20 第32排往下重複 (4)
    down_pipe_y mem36(.clka(clk_25Mhz), .addra(add_36), .douta(data_out_36), .wea(0), .dina(garbage));

    // 下排管子 60*20 第32排往下重複 (5)
    down_pipe mem50(.clka(clk_25Mhz), .addra(add_50), .douta(data_out_50), .wea(0), .dina(garbage));

    // 上排管子 60*20 第1排往上重複 (1)
    top_pipe mem16(.clka(clk_25Mhz), .addra(add_16), .douta(data_out_16), .wea(0), .dina(garbage));

    // 上排管子 60*20 第1排往上重複 (2)
    top_pipe mem17(.clka(clk_25Mhz), .addra(add_17), .douta(data_out_17), .wea(0), .dina(garbage));

    // 上排管子 60*20 第1排往上重複 (3)
    top_pipe mem18(.clka(clk_25Mhz), .addra(add_18), .douta(data_out_18), .wea(0), .dina(garbage));

    // 上排管子 60*20 第1排往上重複 (4)
    top_pipe_y mem37(.clka(clk_25Mhz), .addra(add_37), .douta(data_out_37), .wea(0), .dina(garbage));

    // 上排管子 60*20 第1排往上重複 (5)
    top_pipe mem51(.clka(clk_25Mhz), .addra(add_51), .douta(data_out_51), .wea(0), .dina(garbage));


    // 鳥死掉(正向) 30*30
    dead1 mem19(.clka(clk_25Mhz), .addra(add_19), .douta(data_out_19), .wea(0), .dina(garbage));

    // 鳥死掉(轉向) 30*30
    dead2 mem20(.clka(clk_25Mhz), .addra(add_20), .douta(data_out_20), .wea(0), .dina(garbage));

    // 幽靈 24*24 (1)
    ghost1 mem21(.clka(clk_25Mhz), .addra(add_21), .douta(data_out_21), .wea(0), .dina(garbage));

    // 幽靈 24*24 (2)
    ghost2 mem22(.clka(clk_25Mhz), .addra(add_22), .douta(data_out_22), .wea(0), .dina(garbage));

    // 植物 30*50 (1)
    plant1 mem23(.clka(clk_25Mhz), .addra(add_23), .douta(data_out_23), .wea(0), .dina(garbage));
    
    // 植物 30*50 (2)
    plant2 mem39(.clka(clk_25Mhz), .addra(add_39), .douta(data_out_39), .wea(0), .dina(garbage));

    // 蜘蛛 30*50 
    spider mem24(.clka(clk_25Mhz), .addra(add_24), .douta(data_out_24), .wea(0), .dina(garbage));

    // monkey1
    monkey1 mem25(.clka(clk_25Mhz), .addra(add_25), .douta(data_out_25), .wea(0), .dina(garbage));

    // monkey2
    monkey2 mem26(.clka(clk_25Mhz), .addra(add_26), .douta(data_out_26), .wea(0), .dina(garbage));

    // monkey3
    monkey3 mem27(.clka(clk_25Mhz), .addra(add_27), .douta(data_out_27), .wea(0), .dina(garbage));

    // monkey4
    monkey4 mem28(.clka(clk_25Mhz), .addra(add_28), .douta(data_out_28), .wea(0), .dina(garbage));

    // monkey5
    monkey5 mem29(.clka(clk_25Mhz), .addra(add_29), .douta(data_out_29), .wea(0), .dina(garbage));

    // monkey6
    monkey6 mem30(.clka(clk_25Mhz), .addra(add_30), .douta(data_out_30), .wea(0), .dina(garbage));

    // monkey7
    monkey7 mem31(.clka(clk_25Mhz), .addra(add_31), .douta(data_out_31), .wea(0), .dina(garbage));

    // monkey8
    monkey8 mem32(.clka(clk_25Mhz), .addra(add_32), .douta(data_out_32), .wea(0), .dina(garbage));

    // monkey9
    monkey9 mem33(.clka(clk_25Mhz), .addra(add_33), .douta(data_out_33), .wea(0), .dina(garbage));

    // monkey10
    monkey10 mem34(.clka(clk_25Mhz), .addra(add_34), .douta(data_out_34), .wea(0), .dina(garbage));

    // 香蕉 
    banana mem35 (.clka(clk_25Mhz), .addra(add_35), .douta(data_out_35), .wea(0), .dina(garbage));

    // 鳥巢
    nest mem38 (.clka(clk_25Mhz), .addra(add_38), .douta(data_out_38), .wea(0), .dina(garbage));
    
    //flappybird 94*16
    flappybird mem40 (.clka(clk_25Mhz), .addra(add_40), .douta(data_out_40), .wea(0), .dina(garbage));

    //gamestart 94*14
    gamestart mem41 (.clka(clk_25Mhz), .addra(add_41), .douta(data_out_41), .wea(0), .dina(garbage));

    //gamewin 82*14
    gamewin mem42 (.clka(clk_25Mhz), .addra(add_42), .douta(data_out_42), .wea(0), .dina(garbage));

    //harp1 30*42
    harp1 mem43 (.clka(clk_25Mhz), .addra(add_43), .douta(data_out_43), .wea(0), .dina(garbage));

    //har2 30*42
    harp2 mem44 (.clka(clk_25Mhz), .addra(add_44), .douta(data_out_44), .wea(0), .dina(garbage));

    //harp3 30*42
    harp3 mem45 (.clka(clk_25Mhz), .addra(add_45), .douta(data_out_45), .wea(0), .dina(garbage));

    //harp4 30*42
    harp4 mem46 (.clka(clk_25Mhz), .addra(add_46), .douta(data_out_46), .wea(0), .dina(garbage));

    //ball 12*12
    ball mem47 (.clka(clk_25Mhz), .addra(add_47), .douta(data_out_47), .wea(0), .dina(garbage));

    //ball 12*12
    ball mem48 (.clka(clk_25Mhz), .addra(add_48), .douta(data_out_48), .wea(0), .dina(garbage));

    //ball 12*12
    ball mem49 (.clka(clk_25Mhz), .addra(add_49), .douta(data_out_49), .wea(0), .dina(garbage));
// --------------------------------------------------------------------------------------------

    // 背景圖案的地址 80* 60
    always @(*)begin
        if(v_cnt < 451)begin
            add_1 = 0;
        end
        else begin
            add_1 = (h_cnt % 18) + 18*(v_cnt - 451);
        end
        
    end
    // 遊戲結束 76*76 放大後左上角座標 244,164
    always @(*)begin
        add_3 = ((h_cnt - 244)>>1) + 76*((v_cnt - 164)>>1) ;
    end

    // flappybird 94*16 中心點(320, 140) 左上角 226, 124
    always @(*)begin
        add_40 = ((h_cnt - 226)>>1) + 94*((v_cnt - 124)>>1) ;
    end
    // gamestart 94*14 中心點(320, 346) 左上角 226, 332
    always @(*)begin
        add_41 = ((h_cnt - 226)>>1) + 94*((v_cnt - 332)>>1) ;
    end
    // gamewin 82*14 中心點(320, 140) 左上角 238, 126
    always @(*)begin
        add_42 = ((h_cnt - 238)>>1) + 82*((v_cnt - 126)>>1) ;
    end 
    /*
    // 背景圖案的地址
    always @(*)begin
        add_1 = (h_cnt>>1)+320*(v_cnt>>1);
    end

    // 遊戲結束圖案的地址
    always @(*)begin
        add_3 = (h_cnt>>2)+160*(v_cnt>>2);
    end
    
    */

    // 鳥的圖案的地址，揮動翅膀(1) 
    always @(*)begin
        add_2 = (v_cnt - bird_y + 15)*30 + (h_cnt - bird_x + 15);
    end

    // 鳥的圖案的地址，揮動翅膀(2) 
    always @(*)begin
        add_4 = (v_cnt - bird_y + 15)*30 + (h_cnt - bird_x + 15);
    end

    // 鳥的圖案的地址，鳥往上飛
    always @(*)begin
        add_5 = (v_cnt - bird_y + 15)*30 + (h_cnt - bird_x + 15);
    end

    // 飛彈的圖案的地址
    always @(*)begin
        add_6 = (v_cnt - missle_y + 15)*40 + (h_cnt - missle_x + 20);
    end

    // 兩朵雲 40*20 (cloud1)
    always @(*)begin
        add_7 = (v_cnt - cloud1_y + 10)*40 + (h_cnt - cloud1_x + 20);
    end

   // 一朵雲 20*20 (cloud2)
    always @(*)begin
        add_8 = (v_cnt - cloud2_y + 10)*20 + (h_cnt - cloud2_x + 10);
    end

   // 三朵雲 60*20 (cloud3)
    always @(*)begin
        add_9 = (v_cnt - cloud3_y + 10)*60 + (h_cnt - cloud3_x + 30);
    end

    // 一朵雲 20*20 (cloud4)
    always @(*)begin
        add_10 = (v_cnt - cloud4_y + 10)*20 + (h_cnt - cloud4_x + 10);
    end

    // 三朵雲 60*20 (cloud5)
    always @(*)begin
        add_11 = (v_cnt - cloud5_y + 10)*60 + (h_cnt - cloud5_x + 30);
    end

    
    // 兩朵雲 40*20 (cloud6)
    always @(*)begin
        add_12 = (v_cnt - cloud6_y + 10)*40 + (h_cnt - cloud6_x + 20);
    end
 
    // 下排管子 60*20 第32排往下重複 (1)
    always @(*)begin
        if(v_cnt > (tube1_y + 80) + 16)begin
            add_13 = 19*60 + (h_cnt - tube1_x + 30);
        end
        else begin
            add_13 = (v_cnt - (tube1_y+ 80 + 10) + 10)*60 + (h_cnt - tube1_x + 30);
        end
    end

    // 下排管子 60*20 第32排往下重複 (2)
    always @(*)begin
        if(v_cnt > (tube2_y + 80) + 16)begin
            add_14 = 19*60 + (h_cnt - tube2_x + 30);
        end
        else begin
            add_14 = (v_cnt - (tube2_y+ 80 + 10) + 10)*60 + (h_cnt - tube2_x + 30);
        end   
    end

    // 下排管子 60*20 第32排往下重複 (3)
    always @(*)begin
        if(v_cnt > (tube3_y + 80) + 16)begin
            add_15 = 19*60 + (h_cnt - tube3_x + 30);
        end
        else begin
            add_15 = (v_cnt - (tube3_y+ 80 + 10) + 10)*60 + (h_cnt - tube3_x + 30);
        end
    end
    // 下排管子 60*20 第32排往下重複 (4)
    always @(*)begin
        if(v_cnt > (tube4_y + 80) + 16)begin
            add_36 = 19*60 + (h_cnt - tube4_x + 30);
        end
        else begin
            add_36 = (v_cnt - (tube4_y+ 80 + 10) + 10)*60 + (h_cnt - tube4_x + 30);
        end
    end

    // 下排管子 60*20 第32排往下重複 (5) 開口大小 120 + 120
    always @(*)begin
        if(v_cnt > (tube5_y + 120) + 16)begin
            add_50 = 19*60 + (h_cnt - tube5_x + 30);
        end
        else begin
            add_50 = (v_cnt - (tube5_y + 120 + 10) + 10)*60 + (h_cnt - tube5_x + 30);
        end
    end

    // 上排管子 60*20 第1排往上重複 (1)
    always @(*)begin
        if(v_cnt < (tube1_y - 80) - 16)begin
            add_16 = (h_cnt - tube1_x + 30);
        end
        else begin
            add_16 = (v_cnt - (tube1_y-80 -10) + 10)*60 + (h_cnt - tube1_x + 30);
        end
    end

    // 上排管子 60*20 第1排往上重複 (2)
    always @(*)begin
        if(v_cnt < (tube2_y - 80) - 16)begin
            add_17 = (h_cnt - tube2_x + 30);
        end
        else begin
            add_17 = (v_cnt - (tube2_y-80 -10) + 10)*60 + (h_cnt - tube2_x + 30);
        end
    end

    // 上排管子 60*20 第1排往上重複 (3)
    always @(*)begin
        if(v_cnt < (tube3_y - 80) - 16)begin
            add_18 = (h_cnt - tube3_x + 30);
        end
        else begin
            add_18 = (v_cnt - (tube3_y-80 -10) + 10)*60 + (h_cnt - tube3_x + 30);
        end
    end

    // 上排管子 60*20 第1排往上重複 (4)
    always @(*)begin
        if(v_cnt < (tube4_y - 80) - 16)begin
            add_37 = (h_cnt - tube4_x + 30);
        end
        else begin
            add_37 = (v_cnt - (tube4_y-80 -10) + 10)*60 + (h_cnt - tube4_x + 30);
        end
    end

    // 上排管子 60*20 第1排往上重複 (5)
    always @(*)begin
        if(v_cnt < (tube5_y - 120) - 16)begin
            add_51 = (h_cnt - tube5_x + 30);
        end
        else begin
            add_51 = (v_cnt - (tube5_y- 120 -10) + 10)*60 + (h_cnt - tube5_x + 30);
        end
    end
    
    // 鳥死掉(正向) 30*30
    always @(*)begin
        add_19 = (v_cnt - bird_y + 15)*30 + (h_cnt - bird_x + 15);
    end

    // 鳥死掉(轉向) 30*30
    always @(*)begin
        add_20 = (v_cnt - bird_y + 15)*30 + (h_cnt - bird_x + 15);
    end

    // 幽靈(1) 24*24
    always @(*)begin
        add_21 = (v_cnt - ghost_y + 12)*24 + (h_cnt - ghost_x + 12);
    end

    // 幽靈(2) 24*24
    always @(*)begin
        add_22 = (v_cnt - ghost_y + 12)*24 + (h_cnt - ghost_x + 12);
    end

    // 植物(1) 30*50
    always @(*)begin
        add_23 = (v_cnt - plant_y + 25)*30 + (h_cnt - plant_x + 15);
    end

    // 植物(2) 30*50
    always @(*)begin
        add_39 = (v_cnt - plant_y + 25)*30 + (h_cnt - plant_x + 15);
    end

    // 蜘蛛 30*50
    always @(*)begin
        add_24 = (v_cnt - spider_y + 25)*30 + (h_cnt - spider_x + 15);
    end

    // monkey1 50*56
    always @(*)begin
        add_25 = (v_cnt - monkey_y + 28)*50 + (h_cnt - monkey_x + 25);
    end

    // monkey2
    always @(*)begin
        add_26 = (v_cnt - monkey_y + 28)*50 + (h_cnt - monkey_x + 25);
    end

    // monkey3
    always @(*)begin
        add_27 = (v_cnt - monkey_y + 28)*50 + (h_cnt - monkey_x + 25);
    end

    // monkey4
    always @(*)begin
        add_28 = (v_cnt - monkey_y + 28)*50 + (h_cnt - monkey_x + 25);
    end

    // monkey5
    always @(*)begin
        add_29 = (v_cnt - monkey_y + 28)*50 + (h_cnt - monkey_x + 25);
    end
    
    // monkey6
    always @(*)begin
        add_30 = (v_cnt - monkey_y + 28)*50 + (h_cnt - monkey_x + 25);
    end

    // monkey7
    always @(*)begin
        add_31 = (v_cnt - monkey_y + 28)*50 + (h_cnt - monkey_x + 25);
    end

    // monkey8
    always @(*)begin
        add_32 = (v_cnt - monkey_y + 28)*50 + (h_cnt - monkey_x + 25);
    end

    // monkey9
    always @(*)begin
        add_33 = (v_cnt - monkey_y + 28)*50 + (h_cnt - monkey_x + 25);
    end
    // monkey10
    always @(*)begin
        add_34 = (v_cnt - monkey_y + 28)*50 + (h_cnt - monkey_x + 25);
    end

    // banana 22*20
    always @(*)begin
        add_35 = (v_cnt - banana_y + 10)*22 + (h_cnt - banana_x + 11);
    end

    // nest 60*24
    always @(*)begin
        add_38 = (v_cnt - nest_y + 12)*60 + (h_cnt - nest_x + 30);
    end

    // harp(1) 30*42
    always @(*)begin
        add_43 = (v_cnt - harp_y + 21)*30 + (h_cnt - harp_x + 15);
    end

    // harp 30*42
    always @(*)begin
        add_44 = (v_cnt - harp_y + 21)*30 + (h_cnt - harp_x + 15);
    end

    // harp 30*42
    always @(*)begin
        add_45 = (v_cnt - harp_y + 21)*30 + (h_cnt - harp_x + 15);
    end

    // harp 30*42
    always @(*)begin
        add_46 = (v_cnt - harp_y + 21)*30 + (h_cnt - harp_x + 15);
    end

    // ball 12*12
    always @(*)begin
        add_47 = (v_cnt - ball1_y + 6)*12 + (h_cnt - ball1_x + 6);
    end

    // ball 12*12
    always @(*)begin
        add_48 = (v_cnt - ball2_y + 6)*12 + (h_cnt - ball2_x + 6);
    end

    // ball 12*12
    always @(*)begin
        add_49 = (v_cnt - ball3_y + 6)*12 + (h_cnt - ball3_x + 6);
    end


//--------------------------------------------------------------------------------------------- 
    // turn 的 clock
    always @(posedge clk_turn, posedge rst) begin
        if(rst)begin
            turn_cnt <= 0;
            turn_ok <= 0;
        end
        else begin
            turn_cnt <= next_turn_cnt;
            turn_ok <= next_turn_ok;
        end
    end
    always @(*) begin
        if(over == 1)begin
            next_turn_cnt = turn_cnt + 1;
        end
        else begin
            next_turn_cnt = 0;
        end
        if(turn_cnt > 5)begin
            next_turn_ok = 1;
        end
        else begin
            next_turn_ok = 0;
        end
    end
// --------------------------------------------------------------------------------------------    
    // 灰色影像
    always @(*) begin
        if(bird_state != DEAD || ((h_cnt > 320 - 76) && (h_cnt < 320 + 76) && (v_cnt > 240 - 76) && (v_cnt < 240 + 76)))begin
            pixel = rgb;
        end
        else begin
            pixel = {rgb[11:8] >> 1 , rgb[7:4] >> 1, rgb[3:0] >> 1};
        end
    end
    
    //赋予rgb颜色值
    always @ (*) begin
        //顯示鳥巢
        if((h_cnt > nest_x - 30) && (h_cnt < nest_x + 30) && (v_cnt > nest_y - 12) && (v_cnt < nest_y + 12))begin
            if(data_out_38 == 12'h7CC)begin
                if((h_cnt > bird_x - 15) && (h_cnt < bird_x + 15) && (v_cnt > bird_y - 15) && (v_cnt < bird_y + 15))begin
                    rgb = data_out_4; // bird
                end
                else begin
                    rgb = data_out_1;
                end
            end
            else begin
                rgb = data_out_38; // nest     
            end
        end

        //此區域顯示鳥
        else if ((h_cnt > bird_x - 15) && (h_cnt < bird_x + 15) && (v_cnt > bird_y - 15) && (v_cnt < bird_y + 15))begin
            if(bird_state == UP)begin
                if(data_out_5 == 12'hfff)begin
                    if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                        rgb = data_out_13; // pipe1
                    end
                    else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                        rgb = data_out_14;
                    end
                    else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                        rgb = data_out_15;
                    end
                    else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt >= tube4_y + 80))begin
                        rgb = data_out_36;
                    end
                    else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt >= tube5_y + 120))begin
                        rgb = data_out_50;
                    end
                    else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80)) begin
                        rgb = data_out_16;
                    end
                    else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                        rgb = data_out_17;
                    end
                    else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                        rgb = data_out_18;
                    end
                    else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt <= tube4_y - 80))begin
                        rgb = data_out_37;
                    end
                    else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt <= tube5_y - 120))begin
                        rgb = data_out_51;
                    end
                    else if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                        rgb = data_out_7; // cloud1
                    end
                    else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                        rgb = data_out_8;
                    end
                    else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                        rgb = data_out_9;
                    end
                    else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                        rgb = data_out_10;
                    end
                    else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                        rgb = data_out_11;
                    end
                    else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                        rgb = data_out_12;
                    end
                    else if((h_cnt > plant_x - 15) && (h_cnt < plant_x + 15) && (v_cnt > plant_y - 25) && (v_cnt < plant_y + 25))begin
                        if(cnt == 0)begin
                            rgb = data_out_23;
                        end
                        else begin
                            rgb = data_out_39;
                        end
                    end
                    else if((h_cnt > ghost_x - 12) && (h_cnt < ghost_x + 12) && (v_cnt > ghost_y - 12) && (v_cnt < ghost_y + 12))begin
                        rgb = data_out_21;
                    end
                    else if((h_cnt > missle_x - 20) && (h_cnt < missle_x + 20) && (v_cnt > missle_y - 15) && (v_cnt < missle_y + 15))begin
                        rgb = data_out_6;
                    end
                    else begin
                        rgb = data_out_1; // bg
                    end
                end
                else begin
                    rgb = data_out_5; // fly     
                end      
            end
            else if(((bird_state == DOWN || bird_state == FIX) && cnt == 0))begin
                if(data_out_2 == 12'hfff)begin
                    if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                        rgb = data_out_13; // pipe1
                    end
                    else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                        rgb = data_out_14;
                    end
                    else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                        rgb = data_out_15;
                    end
                    else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt >= tube4_y + 80))begin
                        rgb = data_out_36;
                    end
                    else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt >= tube5_y + 120))begin
                        rgb = data_out_50;
                    end
                    else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80)) begin
                        rgb = data_out_16;
                    end
                    else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                        rgb = data_out_17;
                    end
                    else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                        rgb = data_out_18;
                    end
                    else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt <= tube4_y - 80))begin
                        rgb = data_out_37;
                    end
                    else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt <= tube5_y - 120))begin
                        rgb = data_out_51;
                    end
                    else if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                        rgb = data_out_7; // cloud1
                    end
                    else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                        rgb = data_out_8;
                    end
                    else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                        rgb = data_out_9;
                    end
                    else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                        rgb = data_out_10;
                    end
                    else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                        rgb = data_out_11;
                    end
                    else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                        rgb = data_out_12;
                    end
                    else if((h_cnt > plant_x - 15) && (h_cnt < plant_x + 15) && (v_cnt > plant_y - 25) && (v_cnt < plant_y + 25))begin
                        if(cnt == 0)begin
                            rgb = data_out_23;
                        end
                        else begin
                            rgb = data_out_39;
                        end
                    end
                    else if((h_cnt > ghost_x - 12) && (h_cnt < ghost_x + 12) && (v_cnt > ghost_y - 12) && (v_cnt < ghost_y + 12))begin
                        rgb = data_out_21;
                    end
                    else if((h_cnt > missle_x - 20) && (h_cnt < missle_x + 20) && (v_cnt > missle_y - 15) && (v_cnt < missle_y + 15))begin
                        rgb = data_out_6;
                    end
                    else begin
                        rgb = data_out_1; // bg
                    end
                end
                else begin
                    rgb = data_out_2; // 平飛 bird1    
                end      
            end
            else if(bird_state == DOWN || bird_state == FIX) begin
                if(data_out_4 == 12'hfff)begin
                    if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                        rgb = data_out_13; // pipe1
                    end
                    else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                        rgb = data_out_14;
                    end
                    else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                        rgb = data_out_15;
                    end
                    else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt >= tube4_y + 80))begin
                        rgb = data_out_36;
                    end
                    else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt >= tube5_y + 120))begin
                        rgb = data_out_50;
                    end
                    else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80)) begin
                        rgb = data_out_16;
                    end
                    else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                        rgb = data_out_17;
                    end
                    else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                        rgb = data_out_18;
                    end
                    else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt <= tube4_y - 80))begin
                        rgb = data_out_37;
                    end
                    else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt <= tube5_y - 120))begin
                        rgb = data_out_51;
                    end
                    else if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                        rgb = data_out_7; // cloud1
                    end
                    else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                        rgb = data_out_8;
                    end
                    else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                        rgb = data_out_9;
                    end
                    else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                        rgb = data_out_10;
                    end
                    else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                        rgb = data_out_11;
                    end
                    else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                        rgb = data_out_12;
                    end
                    else if((h_cnt > plant_x - 15) && (h_cnt < plant_x + 15) && (v_cnt > plant_y - 25) && (v_cnt < plant_y + 25))begin
                        if(cnt == 0)begin
                            rgb = data_out_23;
                        end
                        else begin
                            rgb = data_out_39;
                        end
                    end
                    else if((h_cnt > ghost_x - 12) && (h_cnt < ghost_x + 12) && (v_cnt > ghost_y - 12) && (v_cnt < ghost_y + 12))begin
                        rgb = data_out_21;
                    end
                    else if((h_cnt > missle_x - 20) && (h_cnt < missle_x + 20) && (v_cnt > missle_y - 15) && (v_cnt < missle_y + 15))begin
                        rgb = data_out_6;
                    end
                    else begin
                        rgb = data_out_1; // bg
                    end
                end
                else begin
                    rgb = data_out_4; // 平飛 bird2      
                end    
            end
            else if(bird_state == TURN && turn_cnt < 3)begin
                if(data_out_19 == 12'hfff)begin
                    if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                        rgb = data_out_13; // pipe1
                    end
                    else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                        rgb = data_out_14;
                    end
                    else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                        rgb = data_out_15;
                    end
                    else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt >= tube4_y + 80))begin
                        rgb = data_out_36;
                    end
                    else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt >= tube5_y + 120))begin
                        rgb = data_out_50;
                    end
                    else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80)) begin
                        rgb = data_out_16;
                    end
                    else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                        rgb = data_out_17;
                    end
                    else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                        rgb = data_out_18;
                    end
                    else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt <= tube4_y - 80))begin
                        rgb = data_out_37;
                    end
                    else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt <= tube5_y - 120))begin
                        rgb = data_out_51;
                    end
                    else if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                        rgb = data_out_7; // cloud1
                    end
                    else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                        rgb = data_out_8;
                    end
                    else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                        rgb = data_out_9;
                    end
                    else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                        rgb = data_out_10;
                    end
                    else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                        rgb = data_out_11;
                    end
                    else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                        rgb = data_out_12;
                    end
                    else if((h_cnt > plant_x - 15) && (h_cnt < plant_x + 15) && (v_cnt > plant_y - 25) && (v_cnt < plant_y + 25))begin
                        if(cnt == 0)begin
                            rgb = data_out_23;
                        end
                        else begin
                            rgb = data_out_39;
                        end
                    end
                    else if((h_cnt > ghost_x - 12) && (h_cnt < ghost_x + 12) && (v_cnt > ghost_y - 12) && (v_cnt < ghost_y + 12))begin
                        rgb = data_out_21;
                    end
                    else if((h_cnt > missle_x - 20) && (h_cnt < missle_x + 20) && (v_cnt > missle_y - 15) && (v_cnt < missle_y + 15))begin
                        rgb = data_out_6;
                    end
                    else begin
                        rgb = data_out_1; // bg
                    end
                end
                else begin
                    rgb = data_out_19;      
                end    
            end
            else if(bird_state == TURN || bird_state == FALL)begin // turn_cnt >= 3 
                if(data_out_20 == 12'hfff)begin
                    if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                        rgb = data_out_13; // pipe1
                    end
                    else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                        rgb = data_out_14;
                    end
                    else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                        rgb = data_out_15;
                    end
                    else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt >= tube4_y + 80))begin
                        rgb = data_out_36;
                    end
                    else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt >= tube5_y + 120))begin
                        rgb = data_out_50;
                    end
                    else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80)) begin
                        rgb = data_out_16;
                    end
                    else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                        rgb = data_out_17;
                    end
                    else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                        rgb = data_out_18;
                    end
                    else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt <= tube4_y - 80))begin
                        rgb = data_out_37;
                    end
                    else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt <= tube5_y - 120))begin
                        rgb = data_out_51;
                    end
                    else if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                        rgb = data_out_7; // cloud1
                    end
                    else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                        rgb = data_out_8;
                    end
                    else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                        rgb = data_out_9;
                    end
                    else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                        rgb = data_out_10;
                    end
                    else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                        rgb = data_out_11;
                    end
                    else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                        rgb = data_out_12;
                    end
                    else if((h_cnt > plant_x - 15) && (h_cnt < plant_x + 15) && (v_cnt > plant_y - 25) && (v_cnt < plant_y + 25))begin
                        if(cnt == 0)begin
                            rgb = data_out_23;
                        end
                        else begin
                            rgb = data_out_39;
                        end
                    end
                    else if((h_cnt > ghost_x - 12) && (h_cnt < ghost_x + 12) && (v_cnt > ghost_y - 12) && (v_cnt < ghost_y + 12))begin
                        rgb = data_out_21;
                    end
                    else if((h_cnt > missle_x - 20) && (h_cnt < missle_x + 20) && (v_cnt > missle_y - 15) && (v_cnt < missle_y + 15))begin
                        rgb = data_out_6;
                    end
                    else begin
                        rgb = data_out_1; // bg
                    end
                end
                else begin
                    rgb = data_out_20;      
                end    
            end 
            else begin 
                if(data_out_20 == 12'hfff)begin
                    if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                        rgb = data_out_13; // pipe1
                    end
                    else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                        rgb = data_out_14;
                    end
                    else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                        rgb = data_out_15;
                    end
                    else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt >= tube4_y + 80))begin
                        rgb = data_out_36;
                    end
                    else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt >= tube5_y + 120))begin
                        rgb = data_out_50;
                    end
                    else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80)) begin
                        rgb = data_out_16;
                    end
                    else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                        rgb = data_out_17;
                    end
                    else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                        rgb = data_out_18;
                    end
                    else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt <= tube4_y - 80))begin
                        rgb = data_out_37;
                    end
                    else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt <= tube5_y - 120))begin
                        rgb = data_out_51;
                    end
                    else if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                        rgb = data_out_7; // cloud1
                    end
                    else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                        rgb = data_out_8;
                    end
                    else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                        rgb = data_out_9;
                    end
                    else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                        rgb = data_out_10;
                    end
                    else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                        rgb = data_out_11;
                    end
                    else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                        rgb = data_out_12;
                    end
                    else if((h_cnt > plant_x - 15) && (h_cnt < plant_x + 15) && (v_cnt > plant_y - 25) && (v_cnt < plant_y + 25))begin
                        if(cnt == 0)begin
                            rgb = data_out_23;
                        end
                        else begin
                            rgb = data_out_39;
                        end
                    end
                    else if((h_cnt > ghost_x - 12) && (h_cnt < ghost_x + 12) && (v_cnt > ghost_y - 12) && (v_cnt < ghost_y + 12))begin
                        rgb = data_out_21;
                    end
                    else if((h_cnt > missle_x - 20) && (h_cnt < missle_x + 20) && (v_cnt > missle_y - 15) && (v_cnt < missle_y + 15))begin
                        rgb = data_out_6;
                    end
                    else begin
                        rgb = data_out_1; // bg
                    end
                end
                else begin
                    rgb = data_out_20; // 鳥死掉的圖案      
                end    
            end
            
        end
        
        // 顯示飛彈
        else if((h_cnt > missle_x - 20) && (h_cnt < missle_x + 20) && (v_cnt > missle_y - 15) && (v_cnt < missle_y + 15))begin
            if(data_out_6 == 12'h7CC)begin
                if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                    rgb = data_out_13;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                    rgb = data_out_14;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                    rgb = data_out_15;
                end
                else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80))begin
                    rgb = data_out_16;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                    rgb = data_out_17;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                    rgb = data_out_18;
                end
                else begin
                    rgb = data_out_1; // bg
                end
            end
            else begin
                rgb = data_out_6; // missle     
            end
        end

        // 顯示幽靈
        else if((h_cnt > ghost_x - 12) && (h_cnt < ghost_x + 12) && (v_cnt > ghost_y - 12) && (v_cnt < ghost_y + 12) && cnt == 0)begin
            if(data_out_21 == 12'h7CC)begin
                if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                    rgb = data_out_13;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                    rgb = data_out_14;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                    rgb = data_out_15;
                end
                else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80))begin
                    rgb = data_out_16;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                    rgb = data_out_17;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                    rgb = data_out_18;
                end
                else begin
                    rgb = data_out_1; // bg
                end
            end
            else begin
                rgb = data_out_21; // ghost (1)
            end
            
        end  
        else if((h_cnt > ghost_x - 12) && (h_cnt < ghost_x + 12) && (v_cnt > ghost_y - 12) && (v_cnt < ghost_y + 12))begin
            if(data_out_22 == 12'h7CC)begin
                if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                    rgb = data_out_13;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                    rgb = data_out_14;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                    rgb = data_out_15;
                end
                else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80))begin
                    rgb = data_out_16;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                    rgb = data_out_17;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                    rgb = data_out_18;
                end
                else begin
                    rgb = data_out_1; // bg
                end
            end
            else begin
                rgb = data_out_22; // ghost (2)     
            end
        end


        //顯示香蕉 22 *20 
        else if((h_cnt > banana_x - 11) && (h_cnt < banana_x + 11) && (v_cnt > banana_y - 10) && (v_cnt < banana_y + 10))begin
            if(data_out_35 == 12'h7CC)begin
                if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                    rgb = data_out_13;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                    rgb = data_out_14;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                    rgb = data_out_15;
                end
                else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt >= tube5_y + 120))begin
                    rgb = data_out_15;
                end
                else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80))begin
                    rgb = data_out_16;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                    rgb = data_out_17;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                    rgb = data_out_18;
                end
                else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt <= tube5_y - 120))begin
                    rgb = data_out_18;
                end
                else begin
                    rgb = data_out_1; // bg
                end
            end
            else begin
                rgb = data_out_35; // banana     
            end
        end

        // 顯示 ball 1 12*12
        else if((h_cnt > ball1_x - 6) && (h_cnt < ball1_x + 6) && (v_cnt > ball1_y - 6) && (v_cnt < ball1_y + 6))begin
            if(data_out_47 == 12'h7CC)begin
                if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                    rgb = data_out_13;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                    rgb = data_out_14;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                    rgb = data_out_15;
                end
                else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt >= tube5_y + 120))begin
                    rgb = data_out_15;
                end
                else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80))begin
                    rgb = data_out_16;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                    rgb = data_out_17;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                    rgb = data_out_18;
                end
                else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt <= tube5_y - 120))begin
                    rgb = data_out_18;
                end
                else begin
                    rgb = data_out_1; // bg
                end
            end
            else begin
                rgb = data_out_47; // ball1    
            end
        end


        // 顯示 ball 1 12*12
        else if((h_cnt > ball2_x - 6) && (h_cnt < ball2_x + 6) && (v_cnt > ball2_y - 6) && (v_cnt < ball2_y + 6))begin
            if(data_out_48 == 12'h7CC)begin
                if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                    rgb = data_out_13;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                    rgb = data_out_14;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                    rgb = data_out_15;
                end
                else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt >= tube5_y + 120))begin
                    rgb = data_out_15;
                end
                else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80))begin
                    rgb = data_out_16;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                    rgb = data_out_17;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                    rgb = data_out_18;
                end
                else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt <= tube5_y - 120))begin
                    rgb = data_out_18;
                end
                else begin
                    rgb = data_out_1; // bg
                end
            end
            else begin
                rgb = data_out_48; // ball2    
            end
        end

        // 顯示 ball 1 12*12
        else if((h_cnt > ball3_x - 6) && (h_cnt < ball3_x + 6) && (v_cnt > ball3_y - 6) && (v_cnt < ball3_y + 6))begin
            if(data_out_49 == 12'h7CC)begin
                if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                    rgb = data_out_13;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                    rgb = data_out_14;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                    rgb = data_out_15;
                end
                else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt >= tube5_y + 120))begin
                    rgb = data_out_15;
                end
                else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80))begin
                    rgb = data_out_16;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                    rgb = data_out_17;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                    rgb = data_out_18;
                end
                else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt <= tube5_y - 120))begin
                    rgb = data_out_18;
                end
                else begin
                    rgb = data_out_1; // bg
                end
            end
            else begin
                rgb = data_out_49; // ball3    
            end
        end


        // 顯示下排管子，管子寬度為60，管子開口寬度為 80+80=160 
        
        else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
            if(data_out_13 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_13;     
            end
        end

        else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
            if(data_out_14 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_14;     
            end
        end 
        
        else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
            if(data_out_15 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_15;     
            end
        end

        else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt >= tube4_y + 80))begin
            if(data_out_36 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_36;     
            end
        end
        
        else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt >= tube5_y + 120))begin
            if(data_out_50 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_50;     
            end
        end
        // 顯示上排管子
        else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80))begin
            if(data_out_16 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_16;     
            end
        end
        else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
            if(data_out_17 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_17;     
            end
        end
        else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
            if(data_out_18 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_18;     
            end
        end
        else if((h_cnt >= tube4_x - 30) && (h_cnt <= tube4_x + 30) && (v_cnt <= tube4_y - 80))begin
            if(data_out_37 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_37;     
            end
        end
        else if((h_cnt >= tube5_x - 30) && (h_cnt <= tube5_x + 30) && (v_cnt <= tube5_y - 120))begin
            if(data_out_51 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_51;     
            end
        end

        // 顯示植物
        else if((h_cnt > plant_x - 15) && (h_cnt < plant_x + 15) && (v_cnt > plant_y - 25) && (v_cnt < plant_y + 25))begin
            if(cnt == 0)begin
                if(data_out_23 == 12'h7CC)begin
                    rgb = data_out_1; // bg
                end
                else begin
                    rgb = data_out_23; // plant
                end
            end
            else begin
                if(data_out_39 == 12'h7CC)begin
                    rgb = data_out_1; // bg
                end
                else begin
                    rgb = data_out_39; // plant
                end
            end
            
        end

        // 顯示蜘蛛
        else if((h_cnt > spider_x - 15) && (h_cnt < spider_x + 15) && (v_cnt > spider_y - 25) && (v_cnt < spider_y + 25))begin
            if(data_out_24 == 12'h7CC)begin
                if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt >= tube1_y + 80))begin
                    rgb = data_out_13;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt >= tube2_y + 80))begin
                    rgb = data_out_14;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt >= tube3_y + 80))begin
                    rgb = data_out_15;
                end
                else if((h_cnt >= tube1_x - 30) && (h_cnt <= tube1_x + 30) && (v_cnt <= tube1_y - 80))begin
                    rgb = data_out_16;
                end
                else if((h_cnt >= tube2_x - 30) && (h_cnt <= tube2_x + 30) && (v_cnt <= tube2_y - 80))begin
                    rgb = data_out_17;
                end
                else if((h_cnt >= tube3_x - 30) && (h_cnt <= tube3_x + 30) && (v_cnt <= tube3_y - 80))begin
                    rgb = data_out_18;
                end
                else begin
                    rgb = data_out_1; // bg
                end
            end
            else begin
                rgb = data_out_24; // plant
            end
        end


        
        //-------------------------------------------------------------------------
        // 顯示 harp 30*42
        else if((h_cnt > harp_x - 15) && (h_cnt < harp_x + 15) && (v_cnt > harp_y - 21) && (v_cnt < harp_y + 21))begin
            case(harp_state)
                MOVE_0:begin
                    if(cnt == 0)begin
                        if(data_out_43 == 12'h7CC)begin
                            if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                                rgb = data_out_7; // cloud1
                            end
                            else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                                rgb = data_out_8;
                            end
                            else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                                rgb = data_out_9;
                            end
                            else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                                rgb = data_out_10;
                            end
                            else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                                rgb = data_out_11;
                            end
                            else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                                rgb = data_out_12;
                            end
                            else begin
                                rgb = data_out_1; // bg
                            end
                        end
                        else begin
                            rgb = data_out_43; 
                        end
                    end
                    else begin
                        if(data_out_44 == 12'h7CC)begin
                            if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                                rgb = data_out_7; // cloud1
                            end
                            else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                                rgb = data_out_8;
                            end
                            else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                                rgb = data_out_9;
                            end
                            else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                                rgb = data_out_10;
                            end
                            else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                                rgb = data_out_11;
                            end
                            else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                                rgb = data_out_12;
                            end
                            else begin
                                rgb = data_out_1; // bg
                            end
                        end
                        else begin
                            rgb = data_out_44; 
                        end
                    end
                end

                MOVE_1:begin
                    if(cnt == 0)begin
                        if(data_out_43 == 12'h7CC)begin
                            if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                                rgb = data_out_7; // cloud1
                            end
                            else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                                rgb = data_out_8;
                            end
                            else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                                rgb = data_out_9;
                            end
                            else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                                rgb = data_out_10;
                            end
                            else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                                rgb = data_out_11;
                            end
                            else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                                rgb = data_out_12;
                            end
                            else begin
                                rgb = data_out_1; // bg
                            end
                        end
                        else begin
                            rgb = data_out_43; 
                        end
                    end
                    else begin
                        if(data_out_44 == 12'h7CC)begin
                            if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                                rgb = data_out_7; // cloud1
                            end
                            else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                                rgb = data_out_8;
                            end
                            else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                                rgb = data_out_9;
                            end
                            else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                                rgb = data_out_10;
                            end
                            else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                                rgb = data_out_11;
                            end
                            else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                                rgb = data_out_12;
                            end
                            else begin
                                rgb = data_out_1; // bg
                            end
                        end
                        else begin
                            rgb = data_out_44; 
                        end
                    end
                end

                MOVE_2:begin
                    if(data_out_45 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end

                    end
                    else begin
                        rgb = data_out_45; 
                    end
                end

                MOVE_3:begin
                    if(data_out_46 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end
                    end
                    
                    else begin
                        rgb = data_out_46; 
                    end
                end

                HARP_LEAVE:begin
                    if(cnt == 0)begin
                        if(data_out_43 == 12'h7CC)begin
                            if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                                rgb = data_out_7; // cloud1
                            end
                            else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                                rgb = data_out_8;
                            end
                            else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                                rgb = data_out_9;
                            end
                            else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                                rgb = data_out_10;
                            end
                            else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                                rgb = data_out_11;
                            end
                            else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                                rgb = data_out_12;
                            end
                            else begin
                                rgb = data_out_1; // bg
                            end
                        end
                        else begin
                            rgb = data_out_43; 
                        end
                    end
                    else begin
                        if(data_out_44 == 12'h7CC)begin
                            if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                                rgb = data_out_7; // cloud1
                            end
                            else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                                rgb = data_out_8;
                            end
                            else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                                rgb = data_out_9;
                            end
                            else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                                rgb = data_out_10;
                            end
                            else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                                rgb = data_out_11;
                            end
                            else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                                rgb = data_out_12;
                            end
                            else begin
                                rgb = data_out_1; // bg
                            end
                        end
                        else begin
                            rgb = data_out_44; 
                        end
                    end
                end

                HARP_DEAD:begin
                    rgb = data_out_1;
                end

            endcase           
        end

        //--------------------------------------------------------------------------

        // 顯示猴子
        else if((h_cnt > monkey_x - 25) && (h_cnt < monkey_x + 25) && (v_cnt > monkey_y - 28) && (v_cnt < monkey_y + 28))begin
            case(monkey_state)
                MOVE_0:begin
                    if(data_out_25 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end

                    end
                    else begin
                        rgb = data_out_25; 
                    end
                end
                MOVE_1:begin
                    if(data_out_25 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end

                    end
                    else begin
                        rgb = data_out_25; 
                    end
                end
                MOVE_2:begin
                    if(data_out_26 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end
                    end

                    else begin
                        rgb = data_out_26; 
                    end
                end
                MOVE_3:begin
                    if(data_out_27 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end
                    end
                    
                    else begin
                        rgb = data_out_27; 
                    end
                end

                MOVE_4:begin
                    if(data_out_28 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end
                    end
                    
                    else begin
                        rgb = data_out_28; 
                    end
                end
                MOVE_5:begin
                    if(data_out_29 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end
                    end
                    
                    else begin
                        rgb = data_out_29; 
                    end
                end
                MOVE_6:begin
                    if(data_out_30 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end
                    end
                    
                    else begin
                        rgb = data_out_30; 
                    end
                end

                MOVE_7:begin
                    if(data_out_31 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end
                    end
                    
                    else begin
                        rgb = data_out_31; 
                    end
                end
                MOVE_8:begin
                    if(data_out_32 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end
                    end
                    
                    else begin
                        rgb = data_out_32; 
                    end
                end
                MOVE_9:begin
                    if(data_out_33 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end
                    end
                    
                    else begin
                        rgb = data_out_33; 
                    end
                end

                MOVE_10:begin
                    if(data_out_34 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end
                    end
                    
                    else begin
                        rgb = data_out_34; 
                    end
                end
                MONKEY_FALL:begin
                    if(data_out_34 == 12'h7CC)begin
                        if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
                            rgb = data_out_7; // cloud1
                        end
                        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
                            rgb = data_out_8;
                        end
                        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
                            rgb = data_out_9;
                        end
                        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
                            rgb = data_out_10;
                        end
                        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
                            rgb = data_out_11;
                        end
                        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
                            rgb = data_out_12;
                        end
                        else begin
                            rgb = data_out_1; // bg
                        end
                    end
                    
                    else begin
                        rgb = data_out_34; 
                    end
                end
                MONKEY_DEAD:begin
                    rgb = data_out_1;
                end

            endcase           
        end
            

        // 顯示 cloud1
        else if((h_cnt > cloud1_x - 20) && (h_cnt < cloud1_x + 20) && (v_cnt > cloud1_y - 10) && (v_cnt < cloud1_y + 10))begin
            if(data_out_7 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_7;   
            end
        end

        // 顯示 cloud2
        else if((h_cnt > cloud2_x - 10) && (h_cnt < cloud2_x + 10) && (v_cnt > cloud2_y - 10) && (v_cnt < cloud2_y + 10))begin
            if(data_out_8 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_8;     
            end
        end

        // 顯示 cloud3
        else if((h_cnt > cloud3_x - 30) && (h_cnt < cloud3_x + 30) && (v_cnt > cloud3_y - 10) && (v_cnt < cloud3_y + 10))begin
            if(data_out_9 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_9;  
            end
        end

        // 顯示 cloud4
        else if((h_cnt > cloud4_x - 10) && (h_cnt < cloud4_x + 10) && (v_cnt > cloud4_y - 10) && (v_cnt < cloud4_y + 10))begin
            if(data_out_10 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_10;   
            end
        end
        
        // 顯示 cloud5
        else if((h_cnt > cloud5_x - 30) && (h_cnt < cloud5_x + 30) && (v_cnt > cloud5_y - 10) && (v_cnt < cloud5_y + 10))begin
            if(data_out_11 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_11;  
            end
        end
        
        // 顯示 cloud6
        else if((h_cnt > cloud6_x - 20) && (h_cnt < cloud6_x + 20) && (v_cnt > cloud6_y - 10) && (v_cnt < cloud6_y + 10))begin
            if(data_out_12 == 12'h7CC)begin
                rgb = data_out_1; // bg
            end
            else begin
                rgb = data_out_12;    
            end
        end
            
        // 剩下區域顯示背景
        else begin 
            rgb = data_out_1; 
        end 
        
        // 顯示 game over
        if(bird_state == DEAD)begin
            if((h_cnt > 320 - 76) && (h_cnt < 320 + 76) && (v_cnt > 240 - 76) && (v_cnt < 240 + 76))begin
                rgb = data_out_3;    
            end
        end
        // 顯示 flappybird, gamestart
        if(process_state == IDLE)begin
            if((h_cnt > 320 - 94) && (h_cnt < 320 + 94) && (v_cnt > 140 - 16) && (v_cnt < 140 + 16))begin
                rgb = data_out_40;    
            end
            if((h_cnt > 320 - 94) && (h_cnt < 320 + 94) && (v_cnt > 346 - 14) && (v_cnt < 346 + 14))begin
                rgb = data_out_41; 
            end
        end

        // 顯示 gamewin
        if(process_state == WIN)begin
            if((h_cnt > 320 - 82) && (h_cnt < 320 + 82) && (v_cnt > 140 - 14) && (v_cnt < 140 + 14))begin
                rgb = data_out_42; 
            end
        end
        /*
        // flappybird 94*16 中心點(320, 140) 左上角 226, 124
    always @(*)begin
        add_40 = ((h_cnt - 226)>>1) + 94*((v_cnt - 124)>>1) ;
    end
    // gamestart 94*14 中心點(320, 346) 左上角 226, 332
    always @(*)begin
        add_41 = ((h_cnt - 226)>>1) + 94*((v_cnt - 332)>>1) ;
    end
    // gamewin 82*14 中心點(320, 140) 左上角 236, 126
    always @(*)begin
        add_42 = ((h_cnt - 236)>>1) + 82*((v_cnt - 126)>>1) ;
    end 
        */
        
    end 



    always @(posedge clk_wing, posedge rst) begin
        if(rst)begin
            cnt <= 0;
        end
        else begin
            cnt <= next_cnt;
        end
    end
    always @(*) begin
        next_cnt = ~cnt;
        if(over == 1 || process_state == WIN)begin
            next_cnt = cnt;
        end
    end
    
endmodule

module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [15:0] nums,
	input wire rst,
	input wire clk
    );
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		clk_divider <= 15'b0;
    	end else begin
    		clk_divider <= clk_divider + 15'b1;
    	end
    end
    
    always @ (posedge clk_divider[15], posedge rst) begin
    	if (rst) begin
    		display_num <= 4'b0000;
    		digit <= 4'b1111;
    	end else begin
    		case (digit)
    			4'b1110 : begin
    					display_num <= nums[7:4];
    					digit <= 4'b1101;
    				end
    			4'b1101 : begin
						display_num <= 0;
						digit <= 4'b1011;
					end
    			4'b1011 : begin
						display_num <= nums[15:11];
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
    end
    
    always @ (*) begin
    	case (display_num)
    		0 : display = 7'b1000000;	
			1 : display = 7'b1111001;                                                   
			2 : display = 7'b0100100;                                                   
			3 : display = 7'b0110000;                                                
			4 : display = 7'b0011001;                                                  
			5 : display = 7'b0010010;                                                  
			6 : display = 7'b0000010;   
			7 : display = 7'b1111000;   
			8 : display = 7'b0000000;   
			9 : display = 7'b0010000;	
			default : display = 7'b1111111;
    	endcase
    end
    
endmodule

module Top(
    input wire clk,
    input wire rst,
    input _volUP,     // BTNU: Vol up
    input _volDOWN,
    input SW0,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync,
    inout PS2_CLK,
    inout PS2_DATA,
    output [6:0] DISPLAY,
    output [3:0] DIGIT,
    output audio_mclk, 
    output audio_lrck, 
    output audio_sck,
    output audio_sdin
);
    // bird state
    parameter UP = 0;
    parameter DOWN = 1;
    parameter FIX = 2;
    parameter TURN = 3;
    parameter FALL = 4;
    parameter DEAD = 5;

    // process state
    parameter IDLE = 8;
    parameter STAGE1 = 9; // 管子不動
    parameter REMOVE_TUBE_HARP = 10;
    parameter MOVE_TUBE4_HARP = 11;
    parameter HARP_FIGHT = 12;
    parameter REMOVE_TUBE4_HARP = 13;

    parameter STAGE2 = 14; // 管子移動
    parameter STAGE3 = 15; // 管子不動
    parameter REMOVE_TUBE = 16;
    parameter MOVE_TUBE4 = 17;
    parameter BOSS_FIGHT = 18;
    parameter REMOVE_TUBE4 = 19;
    parameter MOVE_NEST = 20;
    parameter WIN = 21;
   
    
    // tube state
    parameter LEFT = 27;
    parameter RIGHT = 28;
    parameter PAUSE = 29;

    // monkey state
    parameter MOVE_0 = 30; // 上升
    parameter MOVE_1 = 31; // ready
    parameter MOVE_2 = 32;
    parameter MOVE_3 = 33;
    parameter MOVE_4 = 34;
    parameter MOVE_5 = 35;
    parameter MOVE_6 = 36;
    parameter MOVE_7 = 37;
    parameter MOVE_8 = 38;
    parameter MOVE_9 = 39;
    parameter MOVE_10 = 40; // 跌倒
    parameter MONKEY_FALL = 41;
    parameter MONKEY_DEAD= 42;

    // harp state
    parameter HARP_LEAVE = 45;
    parameter HARP_DEAD = 46;

    wire [9:0] bird_y;
    wire [31:0] tube1_x, tube1_y;
    wire [31:0] tube2_x, tube2_y;
    wire [31:0] tube3_x, tube3_y;
    wire [31:0] tube4_x, tube4_y;
    wire [31:0] tube5_x;
    wire [31:0] tube5_y;
    wire [31:0] missle_x, missle_y;
    wire [31:0] cloud1_x;
    wire [31:0] cloud1_y;
    wire [31:0] cloud2_x;
    wire [31:0] cloud2_y;
    wire [31:0] cloud3_x;
    wire [31:0] cloud3_y;
    wire [31:0] cloud4_x;
    wire [31:0] cloud4_y;
    wire [31:0] cloud5_x;
    wire [31:0] cloud5_y;
    wire [31:0] cloud6_x;
    wire [31:0] cloud6_y;
    wire [31:0] ghost_x, ghost_y;
    wire [31:0] plant_x, plant_y;
    wire [31:0] spider_x, spider_y;
    wire [31:0] monkey_x;
    wire [31:0] monkey_y;
    wire [31:0] banana_x;
    wire [31:0] banana_y;
    wire [31:0] nest_x;
    wire [31:0] nest_y;
    wire [31:0] harp_x;
    wire [31:0] harp_y;
    wire [31:0] ball1_x; 
    wire [31:0] ball1_y;
    wire [31:0] ball2_x; 
    wire [31:0] ball2_y;
    wire [31:0] ball3_x; 
    wire [31:0] ball3_y;
    
    wire clk_25Mhz;
    wire valid;
    wire [9:0]h_cnt;
    wire [9:0]v_cnt;
    wire over;
    wire [11:0] pixel;
    wire [9:0] score;
    wire [3:0] digit3, digit4; 
    wire [9:0] bird_state;
    wire turn_ok;
    wire [9:0] process_state;
    wire [9:0] monkey_state;
    wire [9:0] harp_state;
    wire [9:0] bird_x;
    reg backspace, next_backspace;
    wire [511:0] key_down;
    wire [8:0] last_change;
    wire been_ready;
    wire win_signal;
    wire score_signal;


    clock_divider #(2) cd1(rst,clk,clk_25Mhz);
    clock_divider #(13) cd2(rst,clk,clk_13);
    clock_divider #(20) cd3(rst,clk,clk_20);
    clock_divider #(23) cd4(rst,clk,clk_23);
    clock_divider #(18) cd5(rst,clk,clk_18);
    clock_divider #(19) cd6(rst,clk,clk_19);
    clock_divider #(25) cd7(rst,clk,clk_25);
    clock_divider #(22) cd8(rst,clk,clk_22);
    clock_divider #(24) cd9(rst,clk,clk_24);

    assign {vgaRed, vgaGreen, vgaBlue} = (valid==1'b1) ? pixel : 12'h0;
    
    // VGA接口模块
    vga_controller v1(clk_25Mhz, rst, hsync, vsync, valid, h_cnt, v_cnt);
    
    // 根據鍵盤輸入控制鳥的 y 座標
    Bird b1(clk, rst, up, over, process_state, turn_ok, PS2_CLK, PS2_DATA, bird_y, bird_state, key_down, been_ready);
    // 生成管子的 x, y 座標，並計算得分, 管子每週期往左移動 1 像素點
    Tube t1(clk_20, clk_18, clk_19, clk_22, clk_24, rst, over,bird_x, bird_state, monkey_state, process_state, harp_state, score, 
                tube1_x, tube1_y, tube2_x,tube2_y, tube3_x, tube3_y, tube4_x, tube4_y, tube5_x, tube5_y,
                missle_x, missle_y,
                cloud1_x, cloud1_y, cloud2_x, cloud2_y, cloud3_x, cloud3_y, cloud4_x, cloud4_y, cloud5_x, cloud5_y, cloud6_x, cloud6_y,
                ghost_x, ghost_y,
                plant_x, plant_y,
                spider_x, spider_y,
                monkey_x, monkey_y,
                banana_x, banana_y,
                nest_x, nest_y,
                harp_x, harp_y,
                ball1_x, ball1_y,
                ball2_x, ball2_y,
                ball3_x, ball3_y,
                backspace,
                score_signal
                );
    // 判斷是否發生碰撞
    Collision c1(clk, rst, SW0, tube1_x, tube1_y, tube2_x,
                     tube2_y, tube3_x, tube3_y, tube4_x, tube4_y, tube5_x, tube5_y,
                     bird_y, missle_x, missle_y, 
                     ghost_x, ghost_y,
                     plant_x, plant_y,
                     spider_x, spider_y,
                     banana_x, banana_y,
                     ball1_x, ball1_y,
                     ball2_x, ball2_y,
                     ball3_x, ball3_y,
                     over,
                     process_state);
    // 顯示遊戲畫面 
    Game_disp game1(clk_20,clk_23,clk_25, rst, process_state, bird_state, monkey_state, harp_state, h_cnt, v_cnt, bird_y,
                        tube1_x, tube1_y, tube2_x, tube2_y, tube3_x, tube3_y, tube4_x, tube4_y, tube5_x, tube5_y,
                        missle_x, missle_y,
                        cloud1_x, cloud1_y, cloud2_x, cloud2_y, cloud3_x, cloud3_y, cloud4_x, cloud4_y, cloud5_x, cloud5_y, cloud6_x, cloud6_y,
                        ghost_x, ghost_y,
                        plant_x, plant_y,
                        spider_x, spider_y,
                        monkey_x, monkey_y,
                        banana_x, banana_y,
                        nest_x, nest_y,
                        harp_x, harp_y,
                        ball1_x, ball1_y,
                        ball2_x, ball2_y,
                        ball3_x, ball3_y,
                        over, clk_25Mhz, pixel, turn_ok, bird_x); 

    assign digit3 = score / 10;
    assign digit4 = score % 10;
    SevenSegment s(DISPLAY, DIGIT, {8'b00000000, digit3, digit4}, rst, clk);
    
    always @(posedge clk, posedge rst) begin
        if(rst)begin
            backspace <= 0;
        end
        else begin
            backspace <= next_backspace;
        end
    end
    always @(*) begin
        next_backspace = backspace;
        if(key_down[9'b001100110] == 1 && been_ready == 1 && (process_state == WIN || bird_state == DEAD))begin
            next_backspace = 1; 
        end
        else if(process_state == IDLE)begin
            next_backspace = 0; 
        end
    end

    assign win_signal = process_state == WIN ? 1 : 0;


    // 音效
    audio a1(clk, rst, score_signal, over, win_signal, _volUP, _volDOWN, audio_mclk, audio_lrck, audio_sck, audio_sdin);

endmodule

module Tube(
    input clk_tube, // 管子移動速度
    input clk_missle, // 飛彈移動速度
    input clk_cloud,
    input clk_plant,
    input clk_monkey,
    input rst,
    input over,
    input [9:0] bird_x,
    input [9:0] bird_state,
    output reg [9:0] monkey_state,
    output reg [9:0] process_state,
    output reg [9:0] harp_state,
    output reg [9:0] score,
    output reg [31:0] tube1_x,
    output reg [31:0] tube1_y,
    output reg[31:0] tube2_x,
    output reg[31:0] tube2_y,
    output reg[31:0] tube3_x,
    output reg[31:0] tube3_y,
    output reg[31:0] tube4_x,
    output reg[31:0] tube4_y,
    output reg[31:0] tube5_x,
    output reg[31:0] tube5_y,
    output reg[31:0] missle_x,
    output reg[31:0] missle_y,
    output reg[31:0] cloud1_x,
    output reg[31:0] cloud1_y,
    output reg[31:0] cloud2_x,
    output reg[31:0] cloud2_y,
    output reg[31:0] cloud3_x,
    output reg[31:0] cloud3_y,
    output reg[31:0] cloud4_x,
    output reg[31:0] cloud4_y,
    output reg[31:0] cloud5_x,
    output reg[31:0] cloud5_y,
    output reg[31:0] cloud6_x,
    output reg[31:0] cloud6_y,
    output reg[31:0] ghost_x,
    output reg[31:0] ghost_y,
    output wire [31:0] plant_x,
    output reg [31:0] plant_y,
    output wire [31:0] spider_x,
    output reg [31:0] spider_y,
    output wire [31:0] monkey_x, 
    output reg [31:0] monkey_y,
    output reg [31:0] banana_x, 
    output reg [31:0] banana_y,
    output reg [31:0] nest_x, 
    output wire [31:0] nest_y,
    output wire [31:0] harp_x,
    output reg [31:0] harp_y,
    output reg [31:0] ball1_x, 
    output reg [31:0] ball1_y,
    output reg [31:0] ball2_x, 
    output reg [31:0] ball2_y,
    output reg [31:0] ball3_x, 
    output reg [31:0] ball3_y,
    input backspace,
    output score_signal
);


reg [9:0] next_score;
reg [9:0] tube1_state, tube2_state, tube3_state, tube4_state;
reg [9:0] next_tube1_state, next_tube2_state, next_tube3_state, next_tube4_state;
reg [31:0] next_tube1_x;
reg [31:0] next_tube1_y;
reg[31:0] next_tube2_x;
reg[31:0] next_tube2_y;
reg[31:0] next_tube3_x;
reg[31:0] next_tube3_y;
reg[31:0] next_tube4_x;
reg[31:0] next_tube4_y;
reg[31:0] next_tube5_x;
reg[31:0] next_tube5_y;
reg ghost_state;
reg missle_launch;
reg ghost_launch;
reg plant_launch;
reg spider_launch;
reg [31:0] banana_cnt;
wire [6:0] rand;
reg [31:0] move_cnt, next_move_cnt;
reg [9:0] next_process_state;

reg [9:0] next_monkey_state;
reg [31:0] monkey_life ,next_monkey_life;
reg [31:0] next_monkey_y;
reg [31:0] counter, next_counter;
reg banana_ready;

reg [9:0] next_harp_state;
reg [31:0] harp_life, next_harp_life;
reg [31:0] next_harp_y;
reg [31:0] harp_counter, next_harp_counter;
reg ball1_ready, ball2_ready, ball3_ready;



assign score_signal = next_score != score ? 1 : 0;

Random r1(clk_tube, rst, rand);

// bird state
parameter UP = 0;
parameter DOWN = 1;
parameter FIX = 2;
parameter TURN = 3;
parameter FALL = 4;
parameter DEAD = 5;

// process state
parameter IDLE = 8;
parameter STAGE1 = 9; // 管子不動
parameter REMOVE_TUBE_HARP = 10;
parameter MOVE_TUBE4_HARP = 11;
parameter HARP_FIGHT = 12;
parameter REMOVE_TUBE4_HARP = 13;

parameter STAGE2 = 14; // 管子移動
parameter STAGE3 = 15; // 管子不動
parameter REMOVE_TUBE = 16;
parameter MOVE_TUBE4 = 17;
parameter BOSS_FIGHT = 18;
parameter REMOVE_TUBE4 = 19;
parameter MOVE_NEST = 20;
parameter WIN = 21;
parameter STAGE1_END = 12;
parameter STAGE2_END = 27;
parameter STAGE3_END = 37;

// tube state
parameter LEFT = 27;
parameter RIGHT = 28;
parameter PAUSE = 29;


// monkey state
parameter MOVE_0 = 30; // 上升
parameter MOVE_1 = 31; // ready
parameter MOVE_2 = 32;
parameter MOVE_3 = 33;
parameter MOVE_4 = 34;
parameter MOVE_5 = 35;
parameter MOVE_6 = 36;
parameter MOVE_7 = 37;
parameter MOVE_8 = 38;
parameter MOVE_9 = 39;
parameter MOVE_10 = 40; // 跌倒
parameter MONKEY_FALL = 41;
parameter MONKEY_DEAD= 42;

// harp state
parameter HARP_LEAVE = 45;
parameter HARP_DEAD = 46;

// score
always @(posedge clk_tube, posedge rst)begin
    if(rst)begin
        score <= 0;
    end
    else begin
        score <= next_score;
    end
end

always @(*) begin
    next_score = score;
    if(process_state == IDLE)begin
        next_score = 0;
    end
    if(tube1_x == 190)begin
        next_score = score + 1;
    end
    if(tube2_x == 190)begin
        next_score = score + 1;    
    end
    if(tube3_x == 190)begin
        next_score = score + 1;
    end
    if(tube4_x == 190)begin
        next_score = score + 1;
    end
    if(tube5_x == 190)begin
        next_score = score + 1;
    end
end


always @(posedge clk_tube, posedge rst)begin
    if(rst)begin // 管子位置初始化
        process_state <= IDLE;
        tube1_x <= 800; // 320
        tube1_y <= 240;
        tube2_x <= 1040; // 560
        tube2_y <= 150;
        tube3_x <= 1280; // 800
        tube3_y <= 180;
        tube4_x <= 1040;
        tube4_y <= 240;
        tube5_x <= 800;
        tube5_y <= 240;
        tube1_state <= UP;
        tube2_state <= DOWN;
        tube3_state <= UP;
        tube4_state <= UP;
        move_cnt <= 0;
    end
    else if(backspace == 1)begin
        process_state <= IDLE;
        tube1_x <= 800; // 320
        tube1_y <= 240;
        tube2_x <= 1040; // 560
        tube2_y <= 150;
        tube3_x <= 1280; // 800
        tube3_y <= 180;
        tube4_x <= 1040;
        tube4_y <= 240;
        tube5_x <= 800;
        tube5_y <= 240;
        tube1_state = UP;
        tube2_state = DOWN;
        tube3_state = UP;
        tube4_state = UP;
        move_cnt = 0;

    end
    else if(over == 0)begin
        process_state <= next_process_state;
        tube1_x <= next_tube1_x; // 320
        tube1_y <= next_tube1_y;
        tube2_x <= next_tube2_x; // 560
        tube2_y <= next_tube2_y;
        tube3_x <= next_tube3_x; // 800
        tube3_y <= next_tube3_y;
        tube4_x <= next_tube4_x;
        tube4_y <= next_tube4_y;
        tube5_x <= next_tube5_x;
        tube5_y <= next_tube5_y;
        tube1_state <= next_tube1_state;
        tube2_state <= next_tube2_state;
        tube3_state <= next_tube3_state;
        tube4_state <= next_tube4_state;
        move_cnt <= next_move_cnt;
    end
end

always @(*) begin
    next_process_state = process_state;
    next_tube1_x = tube1_x; // 320
    next_tube1_y = tube1_y;
    next_tube2_x = tube2_x; // 560
    next_tube2_y = tube2_y;
    next_tube3_x = tube3_x; // 800
    next_tube3_y = tube3_y;
    next_tube4_x = tube4_x;
    next_tube4_y = tube4_y;
    next_tube5_x = tube5_x;
    next_tube5_y = tube5_y;
    next_tube1_state = tube1_state;
    next_tube2_state = tube2_state;
    next_tube3_state = tube3_state;
    next_tube4_state = tube4_state;
    next_move_cnt = 0;
    
    case(process_state)
    IDLE:begin
        if(bird_state != FIX)begin
            next_process_state = STAGE1; 
        end
        // only cloud moving
    end
    STAGE1:begin
        
        // 管子依 clock 的頻率向左平移
        next_tube1_x = tube1_x - 1; 
        next_tube2_x = tube2_x - 1;
        next_tube3_x = tube3_x - 1;

        if(score == STAGE1_END)begin
            next_process_state = REMOVE_TUBE_HARP;
        end

        // 重置管子
        if(tube1_x < 100)begin
            next_tube1_x = 800; // 柱子移動到最左邊，重新回會最右邊
            next_tube1_y = rand + 150; // y 座標為隨機數
        end
        if(tube2_x < 100)begin
            next_tube2_x = 800;
            next_tube2_y = rand + 150;   
        end
        if(tube3_x < 100)begin
            next_tube3_x = 800;
            next_tube3_y = rand + 150;
        end                
    end

    REMOVE_TUBE_HARP:begin 
    
        next_tube1_x = tube1_x - 1;
        next_tube2_x = tube2_x - 1;
        next_tube3_x = tube3_x - 1;
        if(tube1_x > 700 && tube2_x > 700 && tube3_x > 700)begin
            next_process_state = MOVE_TUBE4_HARP;
        end

        if(tube1_x < 100 || tube1_x > 700)begin
            next_tube1_x = 800; // 柱子移動到最左邊，重新回會最右邊
            next_tube1_y = rand + 150; // y 座標為隨機數
        end
        if(tube2_x < 100 || tube2_x > 700)begin
            next_tube2_x = 1040;
            next_tube2_y = rand + 150;   
        end
        if(tube3_x < 100 || tube2_x > 700)begin
            next_tube3_x = 1280;
            next_tube3_y = rand + 150;
        end           
    end

    // MOVE tube 5
    MOVE_TUBE4_HARP:begin
        
        next_tube5_x = tube5_x - 1;
        next_tube4_x = tube4_x - 1;
        if(tube4_x <= 460 && tube5_x <= 220)begin
            next_process_state = HARP_FIGHT;
            next_tube4_state = UP;
        end
        
        /*
        if(tube4_x < 500)begin
            next_tube4_x = tube4_x; 
        end

        if(tube5_x < 220)begin
            next_tube5_x = tube5_x; 
        end*/

    end

    HARP_FIGHT:begin
        
        if(harp_state == MOVE_0)begin
            next_tube4_y = tube4_y;
        end
        else if(harp_state == HARP_DEAD)begin
            next_process_state = REMOVE_TUBE4_HARP;
        end

        else if(harp_state == HARP_LEAVE)begin
            next_tube4_y = tube4_y;
        end

        else if(tube4_state == UP)begin
            next_tube4_y = tube4_y - 1;
            if(tube4_y < 110)begin
                next_tube4_state = DOWN;
            end
            
        end 
        else if(tube4_state == DOWN)begin
            next_tube4_y = tube4_y + 1;
            if(tube4_y > 330)begin
                next_tube4_state = UP;
            end
            
        end
    end

    REMOVE_TUBE4_HARP:begin

        next_tube4_x = tube4_x - 1;
        next_tube5_x = tube5_x - 1;
        if(tube4_x > 700 && tube5_x > 700)begin
            next_process_state = STAGE2;
        end

        if(tube4_x < 100 || tube4_x > 700)begin
            next_tube4_x = 1040;  
            next_tube4_y = 240; 
        end
        
        if(tube5_x < 100 || tube5_x > 700)begin
            next_tube5_x = 800;  
            next_tube5_y = 240; 
        end
    end

    STAGE2:begin 
        

        if(score == STAGE2_END)begin
            next_process_state = STAGE3;
        end
        // 管子上下移動
        if(tube1_state == UP)begin
            if(tube1_y <= 190)begin
                next_tube1_state = DOWN;
            end
            next_tube1_y = tube1_y - 1;
        end 
        else begin
            if(tube1_y >= 270)begin
                next_tube1_state = UP;
            end
            next_tube1_y = tube1_y + 1;
        end

        if(tube2_state == UP)begin
            if(tube2_y <= 190)begin
                next_tube2_state = DOWN;
            end
            next_tube2_y = tube2_y - 1;
        end 
        else begin
            if(tube2_y >= 270)begin
                next_tube2_state = UP;
            end
            next_tube2_y = tube2_y + 1;
        end

        if(tube3_state == UP)begin
            if(tube3_y <= 190)begin
                next_tube3_state = DOWN;
            end
            next_tube3_y = tube3_y - 1;
        end 
        else begin
            if(tube3_y >= 270)begin
                next_tube3_state = UP;
            end
            next_tube3_y = tube3_y + 1;
        end
        
        // 管子依 clock 的頻率向左平移
        next_tube1_x = tube1_x - 1;
        next_tube2_x = tube2_x - 1;
        next_tube3_x = tube3_x - 1;

        // 重置管子
        if(tube1_x < 100)begin
            next_tube1_x = 800; // 柱子移動到最左邊，重新回會最右邊
            next_tube1_y = rand + 150; // y 座標為隨機數
        end
        if(tube2_x < 100)begin
            next_tube2_x = 800;
            next_tube2_y = rand + 150;   
        end
        if(tube3_x < 100)begin
            next_tube3_x = 800;
            next_tube3_y = rand + 150;
        end                
        
    end
    
    STAGE3:begin

        // 管子依 clock 的頻率向左平移
        next_tube1_x = tube1_x - 1; 
        next_tube2_x = tube2_x - 1;
        next_tube3_x = tube3_x - 1;

        if(score == STAGE3_END)begin
            next_process_state = REMOVE_TUBE;
        end

        // 重置管子
        if(tube1_x < 100)begin
            next_tube1_x = 800; // 柱子移動到最左邊，重新回會最右邊
            next_tube1_y = rand + 150; // y 座標為隨機數
        end
        if(tube2_x < 100)begin
            next_tube2_x = 800;
            next_tube2_y = rand + 150;   
        end
        if(tube3_x < 100)begin
            next_tube3_x = 800;
            next_tube3_y = rand + 150;
        end
    end

    REMOVE_TUBE:begin
        
        next_tube1_x = tube1_x - 1;
        next_tube2_x = tube2_x - 1;
        next_tube3_x = tube3_x - 1;
        if(tube1_x < 100 || tube1_x > 700)begin
            next_tube1_x = 800;  
            next_tube1_y = 240; 
        end
        if(tube2_x < 100 || tube2_x > 700)begin
            next_tube2_x = 1040;
            next_tube2_y = rand + 150;   
        end
        if(tube3_x < 100 || tube3_x > 700)begin
            next_tube3_x = 1280;
            next_tube3_y = rand + 150;
        end

        if(tube1_x > 700 && tube2_x > 700 && tube3_x > 700)begin
            next_process_state = MOVE_TUBE4;
        end
    end

    MOVE_TUBE4:begin

        /*
        next_tube4_x = tube4_x - 1;
        if(tube4_x <= 500)begin
            next_process_state = BOSS_FIGHT;
            next_tube4_state = UP;
        end
        */

        next_tube4_x = tube4_x - 1;
        next_tube5_x = tube5_x - 1;
        if(tube4_x <= 500 && tube5_x <= 220)begin
            next_process_state = BOSS_FIGHT;
            next_tube4_state = UP;
        end
        
    end
    
    BOSS_FIGHT:begin
        
        if(monkey_state == MOVE_0)begin
            next_tube4_y = tube4_y;
        end

        else if(monkey_state == MONKEY_DEAD)begin
            next_process_state = REMOVE_TUBE4;
        end
        else if(monkey_state == MONKEY_FALL)begin
            next_tube4_y = tube4_y;
        end
        else if(tube4_state == UP)begin
            next_tube4_y = tube4_y - 1;
            if(tube4_y < 110)begin
                next_tube4_state = DOWN;
            end
            
        end 
        else if(tube4_state == DOWN)begin
            next_tube4_y = tube4_y + 1;
            if(tube4_y > 330)begin
                next_tube4_state = UP;
            end
            
        end
        
    end
    REMOVE_TUBE4:begin
        /*
        next_tube4_x = tube4_x - 1;
        if(tube4_x < 100)begin
            next_process_state = MOVE_NEST;
            next_tube4_x = 1280;  
            next_tube4_y = 240; 
            next_tube3_x = 800;
            next_tube3_y = 180;
        end
        */
        
        next_tube4_x = tube4_x - 1;
        next_tube5_x = tube5_x - 1;
        if(tube4_x > 700 && tube5_x > 700)begin
            next_process_state = MOVE_NEST;
            next_tube4_x = 1280;  
            next_tube4_y = 240; 
            next_tube3_x = 800;
            next_tube3_y = 180;
        end

        if(tube4_x < 100 || tube4_x > 700)begin
            next_tube4_x = 1040;  
            next_tube4_y = 240; 
        end
        
        if(tube5_x < 100 || tube5_x > 700)begin
            next_tube5_x = 800;  
            next_tube5_y = 240; 
        end
        
    end

    MOVE_NEST:begin
        next_tube3_x = tube3_x - 1;
        if(tube3_x == 320 && bird_x == 300)begin
            next_process_state = WIN;
        end
    end
    WIN:begin
        // tube不要再動了
    end
    
    endcase
    
end

    

//missle
/*
always @(posedge clk_missle, posedge rst) begin
    if(rst)begin
       missle_x = 700;
       missle_y = 100;
       missle_launch = 1;
    end
    else if(over == 0)begin
        if(process_state == IDLE)begin
            missle_x = 700;
            missle_y = 100;
            missle_launch = 1;
        end
        if(score == 5)begin
            if(missle_x < 50)begin
                missle_x = 700;
                missle_y = rand + 100; 
                missle_launch = 0;
            end
            else if (missle_launch == 1)begin
                missle_x = missle_x - 1;
            end
        end
        if(score == 8)begin
            missle_launch = 1;
        end
    end
end
*/
always @(posedge clk_missle, posedge rst) begin
    if(rst)begin
       missle_x = 700;
       missle_y = 100;
       missle_launch = 1;
    end
    else if(over == 0)begin
        if(process_state == IDLE)begin
            missle_x = 700;
            missle_y = 100;
            missle_launch = 1;
        end

        else if(score == 18)begin
            if(missle_x < 50)begin
                missle_x = 700;
                missle_y = rand + 100; 
                missle_launch = 0;
            end
            else if (missle_launch == 1)begin
                missle_x = missle_x - 1;
            end
        end
        else if(score == 19)begin
            missle_launch = 1;
        end


        else if(score == 20)begin
            if(missle_x < 50)begin
                missle_x = 700;
                missle_y = rand + 100; 
                missle_launch = 0;
            end
            else if (missle_launch == 1)begin
                missle_x = missle_x - 1;
            end
        end
        else if(score == 21)begin
            missle_launch = 1;
        end

        else if(score == 23)begin
            if(missle_x < 50)begin
                missle_x = 700;
                missle_y = rand + 100; 
                missle_launch = 0;
            end
            else if (missle_launch == 1)begin
                missle_x = missle_x - 1;
            end
        end
        else if(score == 24)begin
            missle_launch = 1;
        end

        else if(score == 26)begin
            if(missle_x < 50)begin
                missle_x = 700;
                missle_y = rand + 100; 
                missle_launch = 0;
            end
            else if (missle_launch == 1)begin
                missle_x = missle_x - 1;
            end
        end
        else if(score == 27)begin
            missle_launch = 1;
        end

        else if(score == 30)begin
            if(missle_x < 50)begin
                missle_x = 700;
                missle_y = rand + 100; 
                missle_launch = 0;
            end
            else if (missle_launch == 1)begin
                missle_x = missle_x - 1;
            end
        end
        else if(score == 31)begin
            missle_launch = 1;
        end

        else if(score == 32)begin
            if(missle_x < 50)begin
                missle_x = 700;
                missle_y = rand + 100; 
                missle_launch = 0;
            end
            else if (missle_launch == 1)begin
                missle_x = missle_x - 1;
            end
        end
        else if(score == 33)begin
            missle_launch = 1;
        end

        else if(score == 35)begin
            if(missle_x < 50)begin
                missle_x = 700;
                missle_y = rand + 100; 
                missle_launch = 0;
            end
            else if (missle_launch == 1)begin
                missle_x = missle_x - 1;
            end
        end
        else if(score == 36)begin
            missle_launch = 1;
        end

        else if(score == 38)begin
            if(missle_x < 50)begin
                missle_x = 700;
                missle_y = rand + 100; 
                missle_launch = 0;
            end
            else if (missle_launch == 1)begin
                missle_x = missle_x - 1;
            end
        end
        else if(score == 39)begin
            missle_launch = 1;
        end
        
    end
end

// cloud
always @(posedge clk_cloud, posedge rst) begin
    if(rst)begin
       cloud1_x = 1000;
       cloud1_y = 80;
       cloud2_x = 800;
       cloud2_y = 120;
       cloud3_x = 900;
       cloud3_y = 165;
       cloud4_x = 1100;
       cloud4_y = 230;
       cloud5_x = 750;
       cloud5_y = 330;
       cloud6_x = 830;
       cloud6_y =  370;
    end
    else if(over == 0)begin
        //重置雲朵
        cloud1_x = cloud1_x - 1;
        cloud2_x = cloud2_x - 1;
        cloud3_x = cloud3_x - 1;
        cloud4_x = cloud4_x - 1;
        cloud5_x = cloud5_x - 1;
        cloud6_x = cloud6_x - 1;
        
        if(cloud1_x < 50)begin
            cloud1_x = 700 + rand%30; 
            cloud1_y = rand + 50; 
        end
        if(cloud2_x < 50)begin
            cloud2_x = 700 + rand%30;
            cloud2_y = rand + 100;   
        end
        if(cloud3_x < 50)begin
            cloud3_x = 700 + rand%30;
            cloud3_y = rand + 150;
        end
        if(cloud4_x < 50)begin
            cloud4_x = 700 + rand%30;
            cloud4_y = rand + 200;
        end
        if(cloud5_x < 50)begin
            cloud5_x = 700 + rand%30;
            cloud5_y = rand+ 250;   
        end
        if(cloud6_x < 50)begin
            cloud6_x = 700 + rand%30;
            cloud6_y = rand + 300;
        end
    end
end

// ghost
/*
always @(posedge clk_cloud, posedge rst) begin
    if(rst)begin
       ghost_x = 700;
       ghost_y = 180;
       ghost_launch = 1;
    end
    else if(over == 0)begin
        if(process_state == IDLE)begin
            ghost_x = 700;
            ghost_y = 180;
            ghost_launch = 1;
        end

        if(ghost_state == UP)begin
            ghost_y = ghost_y - 1;
            if(ghost_y < 100 || rand == 50)begin
                ghost_state = DOWN;
            end
            
        end 
        else begin
            ghost_y = ghost_y + 1;
            if(ghost_y > 300 || rand == 50)begin
                ghost_state = UP;
            end
            
        end
        if(score >= 3 && score <= 4)begin
            if(ghost_x < 50)begin
                ghost_x = 700; 
                ghost_y = rand + rand + 100;
                ghost_launch = 0; 
            end
            else if (ghost_launch == 1)begin
                ghost_x = ghost_x - 1;
            end
        end
        if(score == 5)begin
            ghost_launch = 1;
        end
    end
end
*/
// ghost
always @(posedge clk_cloud, posedge rst) begin
    if(rst)begin
       ghost_x = 700;
       ghost_y = 180;
       ghost_state = UP;
       ghost_launch = 1;
    end
    else if(over == 0)begin


        if(ghost_state == UP)begin
            ghost_y = ghost_y - 1;
            if(ghost_y < 100 || rand == 50)begin
                ghost_state = DOWN;
            end
            
        end 
        else begin
            ghost_y = ghost_y + 1;
            if(ghost_y > 300 || rand == 50)begin
                ghost_state = UP;
            end
            
        end
        

        if(score >= 22 && score <= 23)begin
            if(ghost_x < 50)begin
                ghost_x = 700; 
                ghost_y = rand + rand + 100;
                ghost_launch = 0; 
            end
            else if (ghost_launch == 1)begin
                ghost_x = ghost_x - 1;
            end
            
        end
        else if(score == 24)begin
            ghost_launch = 1;
        end

        else if(score >= 25 && score <= 26)begin
            if(ghost_x < 50)begin
                ghost_x = 700; 
                ghost_y = rand + rand + 100;
                ghost_launch = 0; 
            end
            else if (ghost_launch == 1)begin
                ghost_x = ghost_x - 1;
            end
        end
        else if(score == 27)begin
            ghost_launch = 1;
        end

        else if(score >= 28 && score <= 29)begin
            if(ghost_x < 50)begin
                ghost_x = 700; 
                ghost_y = rand + rand + 100;
                ghost_launch = 0; 
            end
            else if (ghost_launch == 1)begin
                ghost_x = ghost_x - 1;
            end
        end
        else if(score == 30)begin
            ghost_launch = 1;
        end

        else if(score >= 31 && score <= 32)begin
            if(ghost_x < 50)begin
                ghost_x = 700; 
                ghost_y = rand + rand + 100;
                ghost_launch = 0; 
            end
            else if (ghost_launch == 1)begin
                ghost_x = ghost_x - 1;
            end
        end
        else if(score == 33)begin
            ghost_launch = 1;
        end

        else if(score >= 34 && score <= 35)begin
            if(ghost_x < 50)begin
                ghost_x = 700; 
                ghost_y = rand + rand + 100;
                ghost_launch = 0; 
            end
            else if (ghost_launch == 1)begin
                ghost_x = ghost_x - 1;
            end
        end
        else if(score == 36)begin
            ghost_launch = 1;
        end


        if(process_state == IDLE)begin
            ghost_x = 700;
            ghost_y = 180;
            ghost_state = UP;
            ghost_launch = 1;
        end
        
    end
end


// plant (tube2)
/*
assign plant_x = tube2_x;

always @(posedge clk_plant, posedge rst) begin
    if(rst)begin
       plant_y = tube2_y + 80 + 30; // 躲在水管底下 
       plant_launch = 1;
    end
    else if(over == 0)begin  
        if(score >= 1 && score <= 2 && plant_launch == 1)begin
            if(plant_y + 25 <= tube2_y + 80)begin
                
            end
            else begin
                plant_y = plant_y - 1;
            end
            if(plant_x > 640)begin
                plant_launch = 0;
            end
        end

        else begin 
                plant_y = tube2_y + 80 + 30; // 躲回水管底下 
                plant_launch = 1;
        end
    end
end
*/
assign plant_x = tube2_x;

always @(posedge clk_plant, posedge rst) begin
    if(rst)begin
       plant_y = tube2_y + 80 + 30; // 躲在水管底下 
       plant_launch = 1;
    end
    else if(over == 0)begin  
        if(process_state == IDLE)begin
            plant_y = tube2_y + 80 + 30;
        end

        else if(score >= 6 && score <= 7 && plant_launch == 1)begin
            if(plant_y + 25 <= tube2_y + 80)begin
                
            end
            else begin
                plant_y = plant_y - 1;
            end
            if(plant_x > 640)begin
                plant_launch = 0;
            end
        end

        else if(score == 8)begin 
                plant_y = tube2_y + 80 + 30; // 躲回水管底下 
                plant_launch = 1;
        end

        else if(score >= 10 && score <= 11 && plant_launch == 1)begin
            if(plant_y + 25 <= tube2_y + 80)begin
                
            end
            else begin
                plant_y = plant_y - 1;
            end
            if(plant_x > 640)begin
                plant_launch = 0;
            end
        end

        else if(score == 12) begin 
                plant_y = tube2_y + 80 + 30; // 躲回水管底下 
                plant_launch = 1;
        end

        else if(score >= 28 && score <= 29 && plant_launch == 1)begin
            if(plant_y + 25 <= tube2_y + 80)begin
                
            end
            else begin
                plant_y = plant_y - 1;
            end
            if(plant_x > 640)begin
                plant_launch = 0;
            end
        end
        
        else if(score == 30) begin 
                plant_y = tube2_y + 80 + 30; // 躲回水管底下 
                plant_launch = 1;
        end

        else if(score >= 32 && score <= 33 && plant_launch == 1)begin
            if(plant_y + 25 <= tube2_y + 80)begin
                
            end
            else begin
                plant_y = plant_y - 1;
            end
            if(plant_x > 640)begin
                plant_launch = 0;
            end
        end
        
        else if(score == 34) begin 
                plant_y = tube2_y + 80 + 30; // 躲回水管底下 
                plant_launch = 1;
        end

        else if(score >= 35 && score <= 36 && plant_launch == 1)begin
            if(plant_y + 25 <= tube2_y + 80)begin
                
            end
            else begin
                plant_y = plant_y - 1;
            end
            if(plant_x > 640)begin
                plant_launch = 0;
            end
        end
        
        else if(score == 37) begin 
                plant_y = tube2_y + 80 + 30; // 躲回水管底下 
                plant_launch = 1;
        end

        else begin 
                plant_y = tube2_y + 80 + 30; // 躲回水管底下 
                plant_launch = 1;
        end

        
    end
end

// spider (tube1)
/*
assign spider_x = tube1_x;

always @(posedge clk_plant, posedge rst) begin
    if(rst)begin
       spider_y = tube1_y - 80 - 30; // 躲在水管上面 
       spider_launch = 1;
    end
    else if(over == 0)begin  
        if(score >= 3 && score <= 4 && spider_launch == 1)begin
            if(spider_y - 25 >= tube1_y - 80)begin
                
            end
            else begin
                spider_y = spider_y + 1;
            end
            if(spider_x > 640)begin
                spider_launch = 0;
            end
        end

        else begin 
                spider_y = tube1_y - 80 - 30; // 躲回水管底下 
                spider_launch = 1;
        end
    end
end
*/

assign spider_x = tube1_x;

always @(posedge clk_plant, posedge rst) begin
    if(rst)begin
       spider_y = tube1_y - 80 - 30; // 躲在水管上面 
       spider_launch = 1;
    end
    else if(over == 0)begin  
        if(process_state == IDLE)begin
            spider_y = tube1_y - 80 - 30;
        end

        else if(score >= 5 && score <= 6 && spider_launch == 1)begin
            if(spider_y - 25 >= tube1_y - 80)begin
                
            end
            else begin
                spider_y = spider_y + 1;
            end
            if(spider_x > 640)begin
                spider_launch = 0;
            end
        end

        else if(score == 7)begin 
                spider_y = tube1_y - 80 - 30; // 躲回水管底下 
                spider_launch = 1;
        end

        else if(score >= 8 && score <= 9 && spider_launch == 1)begin
            if(spider_y - 25 >= tube1_y - 80)begin
                
            end
            else begin
                spider_y = spider_y + 1;
            end
            if(spider_x > 640)begin
                spider_launch = 0;
            end
        end

        else if(score == 10)begin 
                spider_y = tube1_y - 80 - 30; // 躲回水管底下 
                spider_launch = 1;
        end

        else if(score >= 11 && score <= 12 && spider_launch == 1)begin
            if(spider_y - 25 >= tube1_y - 80)begin
                
            end
            else begin
                spider_y = spider_y + 1;
            end
            if(spider_x > 640)begin
                spider_launch = 0;
            end
        end

        else if(score == 13)begin 
                spider_y = tube1_y - 80 - 30; // 躲回水管底下 
                spider_launch = 1;
        end

        else if(score >= 30 && score <= 31 && spider_launch == 1)begin
            if(spider_y - 25 >= tube1_y - 80)begin
                
            end
            else begin
                spider_y = spider_y + 1;
            end
            if(spider_x > 640)begin
                spider_launch = 0;
            end
        end

        else if(score == 32)begin 
                spider_y = tube1_y - 80 - 30; // 躲回水管底下 
                spider_launch = 1;
        end

        else if(score >= 33 && score <= 34 && spider_launch == 1)begin
            if(spider_y - 25 >= tube1_y - 80)begin
                
            end
            else begin
                spider_y = spider_y + 1;
            end
            if(spider_x > 640)begin
                spider_launch = 0;
            end
        end

        else if(score == 35)begin 
                spider_y = tube1_y - 80 - 30; // 躲回水管底下 
                spider_launch = 1;
        end

        else if(score >= 36 && score <= 37 && spider_launch == 1)begin
            if(spider_y - 25 >= tube1_y - 80)begin
                
            end
            else begin
                spider_y = spider_y + 1;
            end
            if(spider_x > 640)begin
                spider_launch = 0;
            end
        end

        else if(score == 38)begin 
                spider_y = tube1_y - 80 - 30; // 躲回水管底下 
                spider_launch = 1;
        end

        else begin 
                spider_y = tube1_y - 80 - 30; // 躲回水管底下 
                spider_launch = 1;
        end

    end
end



// monkey

assign monkey_x = tube4_x;

always @(posedge clk_tube, posedge rst) begin
    if(rst)begin
       monkey_y <= 460;
       monkey_life <= 0;
       monkey_state <= MOVE_0;
       counter <= 0;
    end
    else if(over == 0)begin
        monkey_state <= next_monkey_state;
        monkey_y <= next_monkey_y;
        monkey_life <= next_monkey_life;
        counter <= next_counter;
    end

end

always @(*) begin
    if(monkey_state != MOVE_0)begin
        next_monkey_life = monkey_life + 1;
    end
    else if(process_state == IDLE)begin
        next_monkey_life = 0;
    end
    else begin
        next_monkey_life = monkey_life;
    end
end

always @(*) begin
    next_monkey_state = monkey_state;
    next_monkey_y = tube4_y + 80 - 28;
    next_counter = counter;
    if(process_state == IDLE)begin
        next_monkey_state = MOVE_0;
    end

    else if(monkey_state == MOVE_0)begin
        if(process_state == BOSS_FIGHT)begin
            next_monkey_y = monkey_y - 1;
            if(monkey_y + 28 < tube4_y + 80)begin
                next_monkey_y = tube4_y + 80 -28;
                next_monkey_state = MOVE_1;
            end    
        end
        else begin
            next_monkey_y = 460;
        end
    end
    else if(monkey_state == MONKEY_FALL)begin
        next_monkey_y = monkey_y + 1;
        if(monkey_y - 28 > tube4_y + 80)begin
            next_monkey_state = MONKEY_DEAD;
        end
    end
    else if(monkey_state == MONKEY_DEAD)begin
        next_monkey_y = 460;
        next_counter = 0;
    end
    else if(counter == 16)begin
        next_counter = 0;
        case(monkey_state)

        MOVE_1:begin
            next_monkey_y = tube4_y + 80 -28;
            // 修改!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            if(monkey_life > 200 * 8)begin
                next_monkey_state = MOVE_10;
            end
            else begin
                next_monkey_state = MOVE_2;
            end
        end
        MOVE_2:begin
            next_monkey_y = tube4_y + 80 -28;
            next_monkey_state = MOVE_3;
        end
        MOVE_3:begin
            next_monkey_y = tube4_y + 80 -28;
            next_monkey_state = MOVE_4;
        end

        MOVE_4:begin
            next_monkey_y = tube4_y + 80 -28;
            next_monkey_state = MOVE_5;
        end
        MOVE_5:begin
            next_monkey_y = tube4_y + 80 -28;
            next_monkey_state = MOVE_6;
        end
        MOVE_6:begin
            next_monkey_y = tube4_y + 80 -28;
            next_monkey_state = MOVE_7;
        end

        MOVE_7:begin
            next_monkey_y = tube4_y + 80 -28;
            next_monkey_state = MOVE_8;
        end
        MOVE_8:begin
            next_monkey_y = tube4_y + 80 -28;
            next_monkey_state = MOVE_9;
        end
        MOVE_9:begin
            next_monkey_y = tube4_y + 80 -28;
            if(banana_ready == 1)begin
                next_monkey_state = rand > 31 ? MOVE_1: MOVE_5;
            end
        end

        MOVE_10:begin
            next_monkey_y = tube4_y + 80 -28;
            next_monkey_state = MONKEY_FALL;
        end
        /*
        MONKEY_FALL:begin
            if(monkey_y - 28 > tube4_y + 80)begin
                next_monkey_state = MONKEY_DEAD;
            end           
        end
        MONKEY_DEAD:begin
            next_monkey_y = 600;
        end
        */
        endcase
    end

    else begin
        next_counter = counter + 1;
    end 
    
end


// harp 30 * 42

assign harp_x = tube4_x;

always @(posedge clk_tube, posedge rst) begin
    if(rst)begin
       harp_y <= 20;
       harp_life <= 0;
       harp_state <= MOVE_0;
       harp_counter <= 0;
    end
    else if(over == 0)begin
        harp_state <= next_harp_state;
        harp_y <= next_harp_y;
        harp_life <= next_harp_life;
        harp_counter <= next_harp_counter;
    end

end

always @(*) begin
    if(harp_state != MOVE_0)begin
        next_harp_life = harp_life + 1;
    end
    else if(process_state == IDLE)begin
        next_harp_life = 0;
    end
    else begin
        next_harp_life = harp_life;
    end
end

always @(*) begin
    next_harp_state = harp_state;
    next_harp_y = tube4_y;
    next_harp_counter = harp_counter;

    if(process_state == IDLE)begin
        next_harp_state = MOVE_0;
    end

    else if(harp_state == MOVE_0)begin
        if(process_state == HARP_FIGHT)begin // 跟 MOVE_1 一樣，正在下降
            next_harp_y = harp_y + 1;
            if(harp_y > tube4_y)begin
                next_harp_y = tube4_y;
                next_harp_state = MOVE_1;
            end
        end
        else begin
            next_harp_y = 20;
        end
    end
    else if(harp_state == HARP_LEAVE)begin
        next_harp_y = harp_y - 1;
        if(harp_y + 21 < tube4_y - 80)begin
            next_harp_state = HARP_DEAD;
        end
    end
    else if(harp_state == HARP_DEAD)begin
        next_harp_y = 20;
        next_harp_counter = 0;
    end
    else if(harp_counter == 16)begin
        next_harp_counter = 0;
        case(harp_state)

        MOVE_1:begin // 在飛
            // 修改!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            next_harp_y = tube4_y;
            if(harp_life > 200 * 8)begin
                next_harp_state = HARP_LEAVE;
            end
            else if(ball1_ready == 1 && ball2_ready == 1 && ball3_ready == 1)begin
                next_harp_state = rand > 31 ? MOVE_1: MOVE_2;
            end
            else begin
                next_harp_state = MOVE_1;
            end
        end
        MOVE_2:begin // 攻擊準備
            next_harp_y = tube4_y;
            next_harp_state = rand > 31 ? MOVE_2: MOVE_3;
        end
        
        MOVE_3:begin // 魔法
            next_harp_y = tube4_y;
            next_harp_state = MOVE_1;
        end
        endcase
    end

    else begin
        next_harp_counter = harp_counter + 1;
    end 
    
end

// ball(1) 直線
always @(posedge clk_cloud, posedge rst) begin
    if(rst)begin
       ball1_x = 700;
       ball1_y = harp_y;
       ball1_ready = 1;
    end
    else if(over == 0)begin
        if(process_state == IDLE)begin
            ball1_x = 700;
            ball1_y = harp_y;
            ball1_ready = 1;
        end
        else if(harp_state == MOVE_3 && ball3_ready == 1)begin
            ball1_x = harp_x - 15;
            ball1_ready = 0; 
        end
        else if(ball1_ready == 0)begin //香蕉正在飛
            if(ball1_x < 50)begin // 重置香蕉
                ball1_x = 700;
                ball1_y = harp_y;
                ball1_ready = 1;
            end
            else begin
                ball1_x = ball1_x - 2;
            end    
        end
        else if(ball1_ready == 1)begin
            ball1_y = harp_y;
        end
    end
end

// ball(2) 往上
always @(posedge clk_cloud, posedge rst) begin
    if(rst)begin
       ball2_x = 700;
       ball2_y = harp_y;
       ball2_ready = 1;
    end
    else if(over == 0)begin
        if(process_state == IDLE)begin
            ball2_x = 700;
            ball2_y = harp_y;
            ball2_ready = 1;
        end
        else if(harp_state == MOVE_3 && ball3_ready == 1)begin
            ball2_x = harp_x - 15;
            ball2_ready = 0;
        end
        else if(ball2_ready == 0)begin //香蕉正在飛
            if(ball2_x < 50 || ball2_y < 10)begin // 重置香蕉
                ball2_x = 700;
                ball2_y = harp_y;
                ball2_ready = 1;
            end
            else begin
                ball2_x = ball2_x - 2;
                ball2_y = ball2_y - 1;
            end    
        end
        else if(ball2_ready == 1)begin
            ball2_y = harp_y;
        end
    end
end

// ball(3) 往下
always @(posedge clk_cloud, posedge rst) begin
    if(rst)begin
       ball3_x = 700;
       ball3_y = harp_y;
       ball3_ready = 1;
    end
    else if(over == 0)begin
        if(process_state == IDLE)begin
            ball3_x = 700;
            ball3_y = harp_y;
            ball3_ready = 1;
        end
        else if(harp_state == MOVE_3 && ball3_ready == 1)begin
            ball3_x = harp_x - 15;
            ball3_ready = 0;
        end
        else if(ball3_ready == 0)begin //香蕉正在飛
            if(ball3_x < 50 || ball2_y > 440)begin // 重置香蕉
                ball3_x = 700;
                ball3_y = harp_y;
                ball3_ready = 1;
            end
            else begin
                ball3_x = ball3_x - 2;
                ball3_y = ball3_y + 1;
            end    
        end
        else if(ball3_ready == 1)begin
            ball3_y = harp_y;
        end
    end
end




// banana 
always @(posedge clk_missle, posedge rst) begin
    if(rst)begin
       banana_x = 700;
       banana_y = monkey_y;
       banana_ready = 1;
    end
    else if(over == 0)begin
        if(process_state == IDLE)begin
            banana_x = 700;
            banana_y = monkey_y;
            banana_ready = 1;
        end

        else if(monkey_state == MOVE_6 && banana_ready == 1)begin
            banana_x = monkey_x - 20;
            banana_ready = 0; 
        end
        else if(banana_ready == 0)begin //香蕉正在飛
            if(banana_x < 50)begin // 重置香蕉
                banana_x = 700;
                banana_y = monkey_y;
                banana_ready = 1;
            end
            else begin
                banana_x = banana_x - 1;
            end    
        end
        else if(banana_ready == 1)begin
            banana_y = monkey_y;
        end
    end
    
end




// nest 60*24
assign nest_y = tube3_y + 80 - 12;
always @(posedge clk_tube, posedge rst) begin
    if(rst)begin
       nest_x = 700;
    end
    else if(over == 0)begin
       if(process_state == REMOVE_TUBE4 || process_state == MOVE_NEST || process_state == WIN)begin
            nest_x = tube3_x;
       end
       else begin
           nest_x = 700;
       end
    end
end

endmodule

module Collision(
    input clk,
    input rst,
    input SW0,
    input [31:0] tube1_x,
    input [31:0] tube1_y,
    input [31:0] tube2_x,
    input [31:0] tube2_y,
    input [31:0] tube3_x,
    input [31:0] tube3_y,
    input [31:0] tube4_x,
    input [31:0] tube4_y,
    input [31:0] tube5_x,
    input [31:0] tube5_y,
    input [9:0] bird_y,
    input [31:0] missle_x,
    input [31:0] missle_y,
    input [31:0] ghost_x,
    input [31:0] ghost_y,
    input [31:0] plant_x,
    input [31:0] plant_y,
    input [31:0] spider_x,
    input [31:0] spider_y,
    input [31:0] banana_x,
    input [31:0] banana_y,
    input [31:0] ball1_x,
    input [31:0] ball1_y,
    input [31:0] ball2_x, 
    input [31:0] ball2_y,
    input [31:0] ball3_x,
    input [31:0] ball3_y,
    output wire over,
    input [9:0] process_state
);

parameter bird_x = 220;
reg collision, next_collision;

assign over = collision == 1 ? 1 : 0;

// process state
parameter IDLE = 8;
parameter STAGE1 = 9; // 管子不動
parameter REMOVE_TUBE_HARP = 10;
parameter MOVE_TUBE4_HARP = 11;
parameter HARP_FIGHT = 12;
parameter REMOVE_TUBE4_HARP = 13;

parameter STAGE2 = 14; // 管子移動
parameter STAGE3 = 15; // 管子不動
parameter REMOVE_TUBE = 16;
parameter MOVE_TUBE4 = 17;
parameter BOSS_FIGHT = 18;
parameter REMOVE_TUBE4 = 19;
parameter MOVE_NEST = 20;
parameter WIN = 21;


// 如果碰到管子或飛彈，就認為發生了碰撞
always @(posedge clk, posedge rst) begin
    if(rst)begin
        collision <= 0;
    end
    else begin
        collision <= next_collision;
    end
end
always @(*) begin
    next_collision = collision;
    if(process_state == IDLE || SW0 == 1)begin
       next_collision = 0;
    end
    else begin
        if((bird_x + 15 >= tube1_x - 30) && (bird_x - 15 <= tube1_x + 30))begin
            if((bird_y + 15 >= tube1_y + 80) || (bird_y - 15 <= tube1_y - 80))begin
                next_collision = 1;             
            end
        end
        
        if((bird_x + 15 >= tube2_x - 30) && (bird_x - 15 <= tube2_x + 30))begin
            if((bird_y + 15 >= tube2_y + 80) || (bird_y - 15 <= tube2_y - 80))begin
                next_collision = 1;             
            end
        end

        if((bird_x + 15 >= tube3_x - 30) && (bird_x - 15 <= tube3_x + 30))begin
            if((bird_y + 15 >= tube3_y + 80) || (bird_y - 15 <= tube3_y - 80))begin
                next_collision = 1;             
            end
        end
        
        if((bird_x + 15 >= tube4_x - 30) && (bird_x - 15 <= tube4_x + 30))begin
            if((bird_y + 15 >= tube4_y + 80) || (bird_y - 15 <= tube4_y - 80))begin
                next_collision = 1;             
            end
        end

        if((bird_x + 15 >= tube5_x - 30) && (bird_x - 15 <= tube5_x + 30))begin
            if((bird_y + 15 >= tube5_y + 120) || (bird_y - 15 <= tube5_y - 120))begin
                next_collision = 1;             
            end
        end
        // 飛彈
        if((bird_x + 15 >= missle_x - 20) && (bird_x - 15 <= missle_x + 20))begin
            if(bird_y <= missle_y)begin // 鳥在飛彈上面
                if(bird_y + 15 >= missle_y - 15)begin  
                    next_collision = 1;
                end
            end
            else begin // 鳥在飛彈下面
                if(bird_y - 15 <= missle_y + 15)begin
                    next_collision = 1;             
                end
            end
        end

        // 幽靈
        if((bird_x + 15 >= ghost_x - 12) && (bird_x - 15 <= ghost_x + 12))begin
            if(bird_y <= ghost_y)begin // 鳥在飛彈上面
                if(bird_y + 15 >= ghost_y - 12)begin  
                    next_collision = 1;
                end
            end
            else begin // 鳥在飛彈下面
                if(bird_y - 15 <= ghost_y + 12)begin
                    next_collision = 1;             
                end
            end
        end

        // 植物
        if((bird_x + 15 >= plant_x - 15) && (bird_x - 15 <= plant_x + 15))begin
            if(bird_y <= plant_y)begin // 鳥在飛彈上面
                if(bird_y + 15 >= plant_y - 25)begin  
                    next_collision = 1;
                end
            end
            else begin // 鳥在飛彈下面
                if(bird_y - 15 <= plant_y + 25)begin
                    next_collision = 1;             
                end
            end
        end

        // 蜘蛛
        if((bird_x + 15 >= spider_x - 15) && (bird_x - 15 <= spider_x + 15))begin
            if(bird_y <= spider_y)begin // 鳥在飛彈上面
                if(bird_y + 15 >= spider_y - 25)begin  
                    next_collision = 1;
                end
            end
            else begin // 鳥在飛彈下面
                if(bird_y - 15 <= spider_y + 25)begin
                    next_collision = 1;             
                end
            end
        end

        // 香蕉
        if((bird_x + 15 >= banana_x - 11) && (bird_x - 15 <= banana_x + 11))begin
            if(bird_y <= banana_y)begin // 鳥在飛彈上面
                if(bird_y + 15 >= banana_y - 10)begin  
                    next_collision = 1;
                end
            end
            else begin // 鳥在飛彈下面
                if(bird_y - 15 <= banana_y + 10)begin
                    next_collision = 1;             
                end
            end
        end

        // ball 1
        if((bird_x + 15 >= ball1_x - 6) && (bird_x - 15 <= ball1_x + 6))begin
            if(bird_y <= ball1_y)begin // 鳥在飛彈上面
                if(bird_y + 15 >= ball1_y - 6)begin  
                    next_collision = 1;
                end
            end
            else begin // 鳥在飛彈下面
                if(bird_y - 15 <= ball1_y + 6)begin
                    next_collision = 1;             
                end
            end
        end

        // ball 2
        if((bird_x + 15 >= ball2_x - 6) && (bird_x - 15 <= ball2_x + 6))begin
            if(bird_y <= ball2_y)begin // 鳥在飛彈上面
                if(bird_y + 15 >= ball2_y - 6)begin  
                    next_collision = 1;
                end
            end
            else begin // 鳥在飛彈下面
                if(bird_y - 15 <= ball2_y + 6)begin
                    next_collision = 1;             
                end
            end
        end

        // ball 3
        if((bird_x + 15 >= ball3_x - 6) && (bird_x - 15 <= ball3_x + 6))begin
            if(bird_y <= ball3_y)begin // 鳥在飛彈上面
                if(bird_y + 15 >= ball3_y - 6)begin  
                    next_collision = 1;
                end
            end
            else begin // 鳥在飛彈下面
                if(bird_y - 15 <= ball3_y + 6)begin
                    next_collision = 1;             
                end
            end
        end
    end
end
    
endmodule

`define _C2  32'd56
`define _D2  32'd73
`define _E2  32'd82
`define _F2  32'd87
`define _G2  32'd98
`define bA2	 32'd104
`define _A2  32'd110
`define bB2  32'd117
`define _B2  32'd123

`define _C3  32'd113 // slow Do
`define bD3  32'd138
`define _D3  32'd147
`define bE3  32'd156
`define _E3  32'd165
`define _F3  32'd174
`define bG3  32'd185
`define _G3  32'd196
`define bA3  32'd208
`define _A3  32'd220
`define bB3  32'd233
`define _B3  32'd247

`define _C4  32'd262 // Do
`define bD4  32'd277
`define _D4  32'd294
`define bE4  32'd311
`define _E4  32'd330
`define _F4  32'd349
`define bG4  32'd370
`define _G4  32'd392
`define bA4  32'd415
`define _A4  32'd440
`define bB4  32'd466
`define _B4  32'd494

`define _C5  32'd523 // high Do
`define bD5  32'd554
`define _D5  32'd587
`define bE5	 32'd622
`define _E5  32'd659
`define _F5  32'd698
`define _G5  32'd784
`define bA5  32'd830
`define _A5  32'd880
`define bB5  32'd932
`define _B5  32'd988

`define _C6 32'd1046
`define _D6 32'd1174
`define bE6 32'd1244
`define _E6 32'd1318
`define _F6 32'd1396
`define _G6 32'd1568
`define bA6 32'd1660
`define _A6 32'd1760
`define bB6 32'd1864
`define _B6 32'd1976

`define _C7 32'd2092

`define sil 32'd50000000

module audio(
    input clk,        // clock
    input rst,        // BTNC
    input in1, // 得分
    input in2, // 碰撞
    input in3, // 通關
    input _volUP,     // BTNU: Vol up
    input _volDOWN,   // BTND: Vol down
    output audio_mclk, // master clock
    output audio_lrck, // left-right clock
    output audio_sck,  // serial clock
    output audio_sdin  // serial audio data input
    );

    // Debounce and Onepulse
    wire vud, vdd, vup, vdp;
    wire in1d, in2d, in3d, in1p, in2p, in3p;

    // Internal Signal
    reg [2:0] volume;
    wire [15:0] audio_in_left, audio_in_right;
    wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3

    // Debounce and Onepulse for sound effect
    debounce d3(
        .pb_debounced(in1d),
        .pb(in1),
        .clk(clk)
    );
    debounce d4(
        .pb_debounced(in2d),
        .pb(in2),
        .clk(clk)
    );
    debounce d5(
        .pb_debounced(in3d),
        .pb(in3),
        .clk(clk)
    );
    onepulse o3(
        .signal(in1d),
        .clk(clk),
        .op(in1p)
    );
    onepulse o4(
        .signal(in2d),
        .clk(clk),
        .op(in2p)
    );
    onepulse o5(
        .signal(in3d),
        .clk(clk),
        .op(in3p)
    );

    // Debounce and Onepulse for volume
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

    // freqL, freqR, DISPLAY, DIGIT, RCT
    freq_gen f(
        .clk(clk),
        .rst(rst),
		.in1(in1p),
    	.in2(in2p),
    	.in3(in3p),
        .freqL(freqL),
        .freqR(freqR)
    );

    // volume
	always @(posedge clk, posedge rst) begin
		if(rst) begin
			volume <= 3'd3;
		end
		else begin
			if(vup && volume!=3'd5) volume <= volume+3'd1;
        	else if(vdp && volume!=3'd1) volume <= volume-3'd1;
		end
	end

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

module freq_gen(
    input clk,
    input rst,
    input in1,
    input in2,
    input in3,
    output reg [31:0] freqL,
    output reg [31:0] freqR
	);

    parameter S0 = 2'd0;
    parameter S1 = 2'd1;
    parameter S2 = 2'd2;
    parameter S3 = 2'd3;

    wire clk_div;
    reg [1:0] state, next_state;
    reg [8:0] beat0, next_beat0;
    reg [3:0] beat1, beat2, next_beat1, next_beat2;
    reg [6:0] beat3, next_beat3;
    wire [31:0] freqL0, freqR0, freqL1, freqR1, freqL2, freqR2, freqL3, freqR3;

    // freqL, freqR
    always @* begin
        case(state)
            // S0: {freqL, freqR} = {32'd50000000, 32'd50000000};
            S0: {freqL, freqR} = {freqL0, freqR0};
            S1: {freqL, freqR} = {freqL1, freqR1};
            S2: {freqL, freqR} = {freqL2, freqR2};
            S3: {freqL, freqR} = {freqL3, freqR3};
        endcase
    end

    // state
    always @(posedge clk, posedge rst) begin
        if(rst) state <= S0;
        else state <= next_state;
    end
    // next_state
    always @* begin
        next_state = state;
        case(state)
            S0: begin
                if(in1) next_state = S1;
                else if(in2) next_state = S2;
                else if(in3) next_state = S3;
            end
            S1: begin
                if(beat1 == 4'd15) next_state = S0;
                else if(in2) next_state = S2;
                else if(in3) next_state = S3;
            end
            S2: begin
                if(beat2 == 4'd15) next_state = S0;
                else if(in1) next_state = S1;
                else if(in3) next_state = S3; 
            end
            S3: begin
                if(beat3 == 7'd127) next_state = S0;
                else if(in1) next_state = S1;
                else if(in2) next_state = S2; 
            end
        endcase
    end

    // beat 0, 1, 2, 3
    always @(posedge clk_div, posedge rst) begin
        if(rst) begin
            beat0 <= 9'd0;
            beat1 <= 4'd0;
            beat2 <= 4'd0;
            beat3 <= 7'd0;
        end
        else begin
            beat0 <= next_beat0;
            beat1 <= next_beat1;
            beat2 <= next_beat2;
            beat3 <= next_beat3;
        end
    end
    // next_beat 0, 1, 2, 3
    always @* begin
        next_beat0 = beat0;
        next_beat1 = 4'd0;
        next_beat2 = 4'd0;
        next_beat3 = 7'd0;
        case(state)
            S0: if(next_state == S0) next_beat0 = beat0+9'd1;
            S1: if(next_state == S1) next_beat1 = beat1+4'd1;
            S2: if(next_state == S2) next_beat2 = beat2+4'd1;
            S3: if(next_state == S3) next_beat3 = beat3+7'd1;
        endcase
    end

    // music0
    music0 m0(
        .beat(beat0),
        .freqL(freqL0),
        .freqR(freqR0)
    );
    // music1
    music1 m1(
        .beat(beat1),
        .freqL(freqL1),
        .freqR(freqR1)
    );
	//music2
	music2 m2(
        .beat(beat2),
        .freqL(freqL2),
        .freqR(freqR2)
    );
    //music3
	music3 m3(
        .beat(beat3),
        .freqL(freqL3),
        .freqR(freqR3)
    );

    // clock_divider
    clock_divider #(.n(22)) c(
		.rst(rst),
        .clk(clk),
        .clk_div(clk_div)
    );

endmodule

module speaker_control(
    clk,  // clock from the crystal
    rst,  // active high reset
    audio_in_left, // left channel audio data input
    audio_in_right, // right channel audio data input
    audio_mclk, // master clock
    audio_lrck, // left-right clock, Word Select clock, or sample rate clock
    audio_sck, // serial clock
    audio_sdin // serial audio data input
    );

    // I/O declaration
    input clk;  // clock from the crystal
    input rst;  // active high reset
    input [15:0] audio_in_left; // left channel audio data input
    input [15:0] audio_in_right; // right channel audio data input
    output audio_mclk; // master clock
    output audio_lrck; // left-right clock
    output audio_sck; // serial clock
    output audio_sdin; // serial audio data input
    reg audio_sdin;

    // Declare internal signal nodes 
    wire [8:0] clk_cnt_next;
    reg [8:0] clk_cnt;
    reg [15:0] audio_left, audio_right;

    // Counter for the clock divider
    assign clk_cnt_next = clk_cnt + 1'b1;

    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            clk_cnt <= 9'd0;
        else
            clk_cnt <= clk_cnt_next;

    // Assign divided clock output
    assign audio_mclk = clk_cnt[1];
    assign audio_lrck = clk_cnt[8];
    assign audio_sck = 1'b1; // use internal serial clock mode

    // audio input data buffer
    always @(posedge clk_cnt[8] or posedge rst)
        if (rst == 1'b1)
            begin
                audio_left <= 16'd0;
                audio_right <= 16'd0;
            end
        else
            begin
                audio_left <= audio_in_left;
                audio_right <= audio_in_right;
            end

    always @*
        case (clk_cnt[8:4])
            5'b00000: audio_sdin = audio_right[0];
            5'b00001: audio_sdin = audio_left[15];
            5'b00010: audio_sdin = audio_left[14];
            5'b00011: audio_sdin = audio_left[13];
            5'b00100: audio_sdin = audio_left[12];
            5'b00101: audio_sdin = audio_left[11];
            5'b00110: audio_sdin = audio_left[10];
            5'b00111: audio_sdin = audio_left[9];
            5'b01000: audio_sdin = audio_left[8];
            5'b01001: audio_sdin = audio_left[7];
            5'b01010: audio_sdin = audio_left[6];
            5'b01011: audio_sdin = audio_left[5];
            5'b01100: audio_sdin = audio_left[4];
            5'b01101: audio_sdin = audio_left[3];
            5'b01110: audio_sdin = audio_left[2];
            5'b01111: audio_sdin = audio_left[1];
            5'b10000: audio_sdin = audio_left[0];
            5'b10001: audio_sdin = audio_right[15];
            5'b10010: audio_sdin = audio_right[14];
            5'b10011: audio_sdin = audio_right[13];
            5'b10100: audio_sdin = audio_right[12];
            5'b10101: audio_sdin = audio_right[11];
            5'b10110: audio_sdin = audio_right[10];
            5'b10111: audio_sdin = audio_right[9];
            5'b11000: audio_sdin = audio_right[8];
            5'b11001: audio_sdin = audio_right[7];
            5'b11010: audio_sdin = audio_right[6];
            5'b11011: audio_sdin = audio_right[5];
            5'b11100: audio_sdin = audio_right[4];
            5'b11101: audio_sdin = audio_right[3];
            5'b11110: audio_sdin = audio_right[2];
            5'b11111: audio_sdin = audio_right[1];
            default: audio_sdin = 1'b0;
        endcase

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
                3'd5: audio_right = (b_clk == 1'b0)?16'h8001:16'h7FFF;
            endcase    
        end
    end
    // assign audio_left = (note_div_left == 22'd1) ? 16'h0000 : 
    //                             (b_clk == 1'b0) ? 16'hE000 : 16'h2000;
    // assign audio_right = (note_div_right == 22'd1) ? 16'h0000 : 
    //                             (c_clk == 1'b0) ? 16'hE000 : 16'h2000;
endmodule

module onepulse(signal, clk, op);
    input signal, clk;
    output reg op;
    
    reg delay;
    
    always @(posedge clk) begin
        if((signal == 1) & (delay == 0)) op <= 1;
        else op <= 0; 
        delay <= signal;
    end
endmodule

module debounce(pb_debounced, pb ,clk);
    output pb_debounced;
    input pb;
    input clk;
    
    reg [6:0] shift_reg;
    always @(posedge clk) begin
        shift_reg[6:1] <= shift_reg[5:0];
        shift_reg[0] <= pb;
    end
    
    assign pb_debounced = shift_reg == 7'b111_1111 ? 1'b1 : 1'b0;
endmodule

module music0(
    input [8:0] beat,
    output reg [31:0] freqL,
    output reg [31:0] freqR
    );
	always @* begin
		case(beat)
			// --- Measure 1 ---
			9'd0: freqL = `bG4;		9'd1: freqL = `bG4;
			9'd2: freqL = `bG4;		9'd3: freqL = `bG4;
			9'd4: freqL = `bG4;		9'd5: freqL = `bG4;
			9'd6: freqL = `bG4;		9'd7: freqL = `bG4;
			9'd8: freqL = `bG4;		9'd9: freqL = `bG4;
			9'd10: freqL = `bG4;		9'd11: freqL = `bG4;
			9'd12: freqL = `bG4;		9'd13: freqL = `bG4;
			9'd14: freqL = `bG4;		9'd15: freqL = `bG4;
			9'd16: freqL = `_A4;		9'd17: freqL = `_A4;
			9'd18: freqL = `_A4;		9'd19: freqL = `_A4;
			9'd20: freqL = `_A4;		9'd21: freqL = `_A4;
			9'd22: freqL = `_A4;		9'd23: freqL = `_A4;
			9'd24: freqL = `bD5;		9'd25: freqL = `bD5;
			9'd26: freqL = `bD5;		9'd27: freqL = `bD5;
			9'd28: freqL = `bD5;		9'd29: freqL = `bD5;
			9'd30: freqL = `bD5;		9'd31: freqL = `bD5;
			9'd32: freqL = `sil;		9'd33: freqL = `sil;
			9'd34: freqL = `sil;		9'd35: freqL = `sil;
			9'd36: freqL = `sil;		9'd37: freqL = `sil;
			9'd38: freqL = `sil;		9'd39: freqL = `sil;
			9'd40: freqL = `_A4;		9'd41: freqL = `_A4;
			9'd42: freqL = `_A4;		9'd43: freqL = `_A4;
			9'd44: freqL = `_A4;		9'd45: freqL = `_A4;
			9'd46: freqL = `_A4;		9'd47: freqL = `_A4;
			9'd48: freqL = `sil;		9'd49: freqL = `sil;
			9'd50: freqL = `sil;		9'd51: freqL = `sil;
			9'd52: freqL = `sil;		9'd53: freqL = `sil;
			9'd54: freqL = `sil;		9'd55: freqL = `sil;
			9'd56: freqL = `bG4;		9'd57: freqL = `bG4;
			9'd58: freqL = `bG4;		9'd59: freqL = `bG4;
			9'd60: freqL = `bG4;		9'd61: freqL = `bG4;
			9'd62: freqL = `bG4;		9'd63: freqL = `bG4;
			// --- Measure 2 ---
			9'd64: freqL = `_D4;		9'd65: freqL = `_D4;
			9'd66: freqL = `_D4;		9'd67: freqL = `_D4;
			9'd68: freqL = `_D4;		9'd69: freqL = `_D4;
			9'd70: freqL = `_D4;		9'd71: freqL = `sil;
			9'd72: freqL = `_D4;		9'd73: freqL = `_D4;
			9'd74: freqL = `_D4;		9'd75: freqL = `_D4;
			9'd76: freqL = `_D4;		9'd77: freqL = `_D4;
			9'd78: freqL = `_D4;		9'd79: freqL = `sil;
			9'd80: freqL = `_D4;		9'd81: freqL = `_D4;
			9'd82: freqL = `_D4;		9'd83: freqL = `_D4;
			9'd84: freqL = `_D4;		9'd85: freqL = `_D4;
			9'd86: freqL = `_D4;		9'd87: freqL = `_D4;
			9'd88: freqL = `sil;		9'd89: freqL = `sil;
			9'd90: freqL = `sil;		9'd91: freqL = `sil;
			9'd92: freqL = `sil;		9'd93: freqL = `sil;
			9'd94: freqL = `sil;		9'd95: freqL = `sil;
			9'd96: freqL = `sil;		9'd97: freqL = `sil;
			9'd98: freqL = `sil;		9'd99: freqL = `sil;
			9'd100: freqL = `sil;		9'd101: freqL = `sil;
			9'd102: freqL = `sil;		9'd103: freqL = `sil;
			9'd104: freqL = `sil;		9'd105: freqL = `sil;
			9'd106: freqL = `sil;		9'd107: freqL = `sil;
			9'd108: freqL = `sil;		9'd109: freqL = `sil;
			9'd110: freqL = `sil;		9'd111: freqL = `sil;
			9'd112: freqL = `sil;		9'd113: freqL = `sil;
			9'd114: freqL = `sil;		9'd115: freqL = `sil;
			9'd116: freqL = `sil;		9'd117: freqL = `sil;
			9'd118: freqL = `sil;		9'd119: freqL = `sil;
			9'd120: freqL = `bD4;		9'd121: freqL = `bD4;
			9'd122: freqL = `bD4;		9'd123: freqL = `bD4;
			9'd124: freqL = `bD4;		9'd125: freqL = `bD4;
			9'd126: freqL = `bD4;		9'd127: freqL = `bD4;
			// --- Measure 3 ---
			9'd128: freqL = `_D4;		9'd129: freqL = `_D4;
			9'd130: freqL = `_D4;		9'd131: freqL = `_D4;
			9'd132: freqL = `_D4;		9'd133: freqL = `_D4;
			9'd134: freqL = `_D4;		9'd135: freqL = `_D4;
			9'd136: freqL = `bG4;		9'd137: freqL = `bG4;
			9'd138: freqL = `bG4;		9'd139: freqL = `bG4;
			9'd140: freqL = `bG4;		9'd141: freqL = `bG4;
			9'd142: freqL = `bG4;		9'd143: freqL = `bG4;
			9'd144: freqL = `_A4;		9'd145: freqL = `_A4;
			9'd146: freqL = `_A4;		9'd147: freqL = `_A4;
			9'd148: freqL = `_A4;		9'd149: freqL = `_A4;
			9'd150: freqL = `_A4;		9'd151: freqL = `_A4;
			9'd152: freqL = `bD5;		9'd153: freqL = `bD5;
			9'd154: freqL = `bD5;		9'd155: freqL = `bD5;
			9'd156: freqL = `bD5;		9'd157: freqL = `bD5;
			9'd158: freqL = `bD5;		9'd159: freqL = `bD5;
			9'd160: freqL = `sil;		9'd161: freqL = `sil;
			9'd162: freqL = `sil;		9'd163: freqL = `sil;
			9'd164: freqL = `sil;		9'd165: freqL = `sil;
			9'd166: freqL = `sil;		9'd167: freqL = `sil;
			9'd168: freqL = `_A4;		9'd169: freqL = `_A4;
			9'd170: freqL = `_A4;		9'd171: freqL = `_A4;
			9'd172: freqL = `_A4;		9'd173: freqL = `_A4;
			9'd174: freqL = `_A4;		9'd175: freqL = `_A4;
			9'd176: freqL = `sil;		9'd177: freqL = `sil;
			9'd178: freqL = `sil;		9'd179: freqL = `sil;
			9'd180: freqL = `sil;		9'd181: freqL = `sil;
			9'd182: freqL = `sil;		9'd183: freqL = `sil;
			9'd184: freqL = `bG4;		9'd185: freqL = `bG4;
			9'd186: freqL = `bG4;		9'd187: freqL = `bG4;
			9'd188: freqL = `bG4;		9'd189: freqL = `bG4;
			9'd190: freqL = `bG4;		9'd191: freqL = `bG4;
			// --- Measure 4 ---
			9'd192: freqL = `_E5;		9'd193: freqL = `_E5;
			9'd194: freqL = `_E5;		9'd195: freqL = `_E5;
			9'd196: freqL = `_E5;		9'd197: freqL = `_E5;
			9'd198: freqL = `_E5;		9'd199: freqL = `_E5;
			9'd200: freqL = `_E5;		9'd201: freqL = `_E5;
			9'd202: freqL = `_E5;		9'd203: freqL = `_E5;
			9'd204: freqL = `_E5;		9'd205: freqL = `_E5;
			9'd206: freqL = `_E5;		9'd207: freqL = `_E5;
			9'd208: freqL = `bE5;		9'd209: freqL = `bE5;
			9'd210: freqL = `bE5;		9'd211: freqL = `bE5;
			9'd212: freqL = `bE5;		9'd213: freqL = `bE5;
			9'd214: freqL = `bE5;		9'd215: freqL = `bE5;
			9'd216: freqL = `bE5;		9'd217: freqL = `bE5;
			9'd218: freqL = `bE5;		9'd219: freqL = `bE5;
			9'd220: freqL = `bE5;		9'd221: freqL = `bE5;
			9'd222: freqL = `bE5;		9'd223: freqL = `bE5;
			9'd224: freqL = `_D5;		9'd225: freqL = `_D5;
			9'd226: freqL = `_D5;		9'd227: freqL = `_D5;
			9'd228: freqL = `_D5;		9'd229: freqL = `_D5;
			9'd230: freqL = `_D5;		9'd231: freqL = `_D5;
			9'd232: freqL = `_D5;		9'd233: freqL = `_D5;
			9'd234: freqL = `_D5;		9'd235: freqL = `_D5;
			9'd236: freqL = `_D5;		9'd237: freqL = `_D5;
			9'd238: freqL = `_D5;		9'd239: freqL = `_D5;
			9'd240: freqL = `sil;		9'd241: freqL = `sil;
			9'd242: freqL = `sil;		9'd243: freqL = `sil;
			9'd244: freqL = `sil;		9'd245: freqL = `sil;
			9'd246: freqL = `sil;		9'd247: freqL = `sil;
			9'd248: freqL = `sil;		9'd249: freqL = `sil;
			9'd250: freqL = `sil;		9'd251: freqL = `sil;
			9'd252: freqL = `sil;		9'd253: freqL = `sil;
			9'd254: freqL = `sil;		9'd255: freqL = `sil;
			// --- Measure 5 ---
			9'd256: freqL = `bA4;		9'd257: freqL = `bA4;
			9'd258: freqL = `bA4;		9'd259: freqL = `bA4;
			9'd260: freqL = `bA4;		9'd261: freqL = `bA4;
			9'd262: freqL = `bA4;		9'd263: freqL = `bA4;
			9'd264: freqL = `sil;		9'd265: freqL = `sil;
			9'd266: freqL = `sil;		9'd267: freqL = `sil;
			9'd268: freqL = `sil;		9'd269: freqL = `sil;
			9'd270: freqL = `sil;		9'd271: freqL = `sil;
			9'd272: freqL = `bD5;		9'd273: freqL = `bD5;
			9'd274: freqL = `bD5;		9'd275: freqL = `bD5;
			9'd276: freqL = `bD5;		9'd277: freqL = `bD5;
			9'd278: freqL = `bD5;		9'd279: freqL = `bD5;
			9'd280: freqL = `bG4;		9'd281: freqL = `bG4;
			9'd282: freqL = `bG4;		9'd283: freqL = `bG4;
			9'd284: freqL = `bG4;		9'd285: freqL = `bG4;
			9'd286: freqL = `bG4;		9'd287: freqL = `bG4;
			9'd288: freqL = `sil;		9'd289: freqL = `sil;
			9'd290: freqL = `sil;		9'd291: freqL = `sil;
			9'd292: freqL = `sil;		9'd293: freqL = `sil;
			9'd294: freqL = `sil;		9'd295: freqL = `sil;
			9'd296: freqL = `bD5;		9'd297: freqL = `bD5;
			9'd298: freqL = `bD5;		9'd299: freqL = `bD5;
			9'd300: freqL = `bD5;		9'd301: freqL = `bD5;
			9'd302: freqL = `bD5;		9'd303: freqL = `bD5;
			9'd304: freqL = `sil;		9'd305: freqL = `sil;
			9'd306: freqL = `sil;		9'd307: freqL = `sil;
			9'd308: freqL = `sil;		9'd309: freqL = `sil;
			9'd310: freqL = `sil;		9'd311: freqL = `sil;
			9'd312: freqL = `bA4;		9'd313: freqL = `bA4;
			9'd314: freqL = `bA4;		9'd315: freqL = `bA4;
			9'd316: freqL = `bA4;		9'd317: freqL = `bA4;
			9'd318: freqL = `bA4;		9'd319: freqL = `bA4;
			// --- Measure 6 ---
			9'd320: freqL = `sil;		9'd321: freqL = `sil;
			9'd322: freqL = `sil;		9'd323: freqL = `sil;
			9'd324: freqL = `sil;		9'd325: freqL = `sil;
			9'd326: freqL = `sil;		9'd327: freqL = `sil;
			9'd328: freqL = `bD5;		9'd329: freqL = `bD5;
			9'd330: freqL = `bD5;		9'd331: freqL = `bD5;
			9'd332: freqL = `bD5;		9'd333: freqL = `bD5;
			9'd334: freqL = `bD5;		9'd335: freqL = `bD5;
			9'd336: freqL = `sil;		9'd337: freqL = `sil;
			9'd338: freqL = `sil;		9'd339: freqL = `sil;
			9'd340: freqL = `sil;		9'd341: freqL = `sil;
			9'd342: freqL = `sil;		9'd343: freqL = `sil;
			9'd344: freqL = `_G4;		9'd345: freqL = `_G4;
			9'd346: freqL = `_G4;		9'd347: freqL = `_G4;
			9'd348: freqL = `_G4;		9'd349: freqL = `_G4;
			9'd350: freqL = `_G4;		9'd351: freqL = `_G4;
			9'd352: freqL = `bG4;		9'd353: freqL = `bG4;
			9'd354: freqL = `bG4;		9'd355: freqL = `bG4;
			9'd356: freqL = `bG4;		9'd357: freqL = `bG4;
			9'd358: freqL = `bG4;		9'd359: freqL = `bG4;
			9'd360: freqL = `sil;		9'd361: freqL = `sil;
			9'd362: freqL = `sil;		9'd363: freqL = `sil;
			9'd364: freqL = `sil;		9'd365: freqL = `sil;
			9'd366: freqL = `sil;		9'd367: freqL = `sil;
			9'd368: freqL = `_E4;		9'd369: freqL = `_E4;
			9'd370: freqL = `_E4;		9'd371: freqL = `_E4;
			9'd372: freqL = `_E4;		9'd373: freqL = `_E4;
			9'd374: freqL = `_E4;		9'd375: freqL = `_E4;
			9'd376: freqL = `sil;		9'd377: freqL = `sil;
			9'd378: freqL = `sil;		9'd379: freqL = `sil;
			9'd380: freqL = `sil;		9'd381: freqL = `sil;
			9'd382: freqL = `sil;		9'd383: freqL = `sil;
			// --- Measure 7 ---
			9'd384: freqL = `_C4;		9'd385: freqL = `_C4;
			9'd386: freqL = `_C4;		9'd387: freqL = `_C4;
			9'd388: freqL = `_C4;		9'd389: freqL = `_C4;
			9'd390: freqL = `_C4;		9'd391: freqL = `sil;
			9'd392: freqL = `_C4;		9'd393: freqL = `_C4;
			9'd394: freqL = `_C4;		9'd395: freqL = `_C4;
			9'd396: freqL = `_C4;		9'd397: freqL = `_C4;
			9'd398: freqL = `_C4;		9'd399: freqL = `sil;
			9'd400: freqL = `_C4;		9'd401: freqL = `_C4;
			9'd402: freqL = `_C4;		9'd403: freqL = `_C4;
			9'd404: freqL = `_C4;		9'd405: freqL = `_C4;
			9'd406: freqL = `_C4;		9'd407: freqL = `_C4;
			9'd408: freqL = `sil;		9'd409: freqL = `sil;
			9'd410: freqL = `sil;		9'd411: freqL = `sil;
			9'd412: freqL = `sil;		9'd413: freqL = `sil;
			9'd414: freqL = `sil;		9'd415: freqL = `sil;
			9'd416: freqL = `sil;		9'd417: freqL = `sil;
			9'd418: freqL = `sil;		9'd419: freqL = `sil;
			9'd420: freqL = `sil;		9'd421: freqL = `sil;
			9'd422: freqL = `sil;		9'd423: freqL = `sil;
			9'd424: freqL = `sil;		9'd425: freqL = `sil;
			9'd426: freqL = `sil;		9'd427: freqL = `sil;
			9'd428: freqL = `sil;		9'd429: freqL = `sil;
			9'd430: freqL = `sil;		9'd431: freqL = `sil;
			9'd432: freqL = `_C4;		9'd433: freqL = `_C4;
			9'd434: freqL = `_C4;		9'd435: freqL = `_C4;
			9'd436: freqL = `_C4;		9'd437: freqL = `_C4;
			9'd438: freqL = `_C4;		9'd439: freqL = `sil;
			9'd440: freqL = `_C4;		9'd441: freqL = `_C4;
			9'd442: freqL = `_C4;		9'd443: freqL = `_C4;
			9'd444: freqL = `_C4;		9'd445: freqL = `_C4;
			9'd446: freqL = `_C4;		9'd447: freqL = `sil;
			// --- Measure 8 ---
			9'd448: freqL = `_C4;		9'd449: freqL = `_C4;
			9'd450: freqL = `_C4;		9'd451: freqL = `_C4;
			9'd452: freqL = `_C4;		9'd453: freqL = `_C4;
			9'd454: freqL = `_C4;		9'd455: freqL = `_C4;
			9'd456: freqL = `sil;		9'd457: freqL = `sil;
			9'd458: freqL = `sil;		9'd459: freqL = `sil;
			9'd460: freqL = `sil;		9'd461: freqL = `sil;
			9'd462: freqL = `sil;		9'd463: freqL = `sil;
			9'd464: freqL = `sil;		9'd465: freqL = `sil;
			9'd466: freqL = `sil;		9'd467: freqL = `sil;
			9'd468: freqL = `sil;		9'd469: freqL = `sil;
			9'd470: freqL = `sil;		9'd471: freqL = `sil;
			9'd472: freqL = `sil;		9'd473: freqL = `sil;
			9'd474: freqL = `sil;		9'd475: freqL = `sil;
			9'd476: freqL = `sil;		9'd477: freqL = `sil;
			9'd478: freqL = `sil;		9'd479: freqL = `sil;
			9'd480: freqL = `bE4;		9'd481: freqL = `bE4;
			9'd482: freqL = `bE4;		9'd483: freqL = `bE4;
			9'd484: freqL = `bE4;		9'd485: freqL = `bE4;
			9'd486: freqL = `bE4;		9'd487: freqL = `bE4;
			9'd488: freqL = `bE4;		9'd489: freqL = `bE4;
			9'd490: freqL = `bE4;		9'd491: freqL = `bE4;
			9'd492: freqL = `bE4;		9'd493: freqL = `bE4;
			9'd494: freqL = `bE4;		9'd495: freqL = `bE4;
			9'd496: freqL = `_D4;		9'd497: freqL = `_D4;
			9'd498: freqL = `_D4;		9'd499: freqL = `_D4;
			9'd500: freqL = `_D4;		9'd501: freqL = `_D4;
			9'd502: freqL = `_D4;		9'd503: freqL = `_D4;
			9'd504: freqL = `_D4;		9'd505: freqL = `_D4;
			9'd506: freqL = `_D4;		9'd507: freqL = `_D4;
			9'd508: freqL = `_D4;		9'd509: freqL = `_D4;
			9'd510: freqL = `_D4;		9'd511: freqL = `_D4;
		endcase
	end
	always @* begin
		case(beat)
			// --- Measure 1 ---
			9'd0: freqR = `_D4;		9'd1: freqR = `_D4;
			9'd2: freqR = `_D4;		9'd3: freqR = `_D4;
			9'd4: freqR = `_D4;		9'd5: freqR = `_D4;
			9'd6: freqR = `_D4;		9'd7: freqR = `_D4;
			9'd8: freqR = `_D4;		9'd9: freqR = `_D4;
			9'd10: freqR = `_D4;		9'd11: freqR = `_D4;
			9'd12: freqR = `_D4;		9'd13: freqR = `_D4;
			9'd14: freqR = `_D4;		9'd15: freqR = `_D4;
			9'd16: freqR = `sil;		9'd17: freqR = `sil;
			9'd18: freqR = `sil;		9'd19: freqR = `sil;
			9'd20: freqR = `sil;		9'd21: freqR = `sil;
			9'd22: freqR = `sil;		9'd23: freqR = `sil;
			9'd24: freqR = `sil;		9'd25: freqR = `sil;
			9'd26: freqR = `sil;		9'd27: freqR = `sil;
			9'd28: freqR = `sil;		9'd29: freqR = `sil;
			9'd30: freqR = `sil;		9'd31: freqR = `sil;
			9'd32: freqR = `sil;		9'd33: freqR = `sil;
			9'd34: freqR = `sil;		9'd35: freqR = `sil;
			9'd36: freqR = `sil;		9'd37: freqR = `sil;
			9'd38: freqR = `sil;		9'd39: freqR = `sil;
			9'd40: freqR = `sil;		9'd41: freqR = `sil;
			9'd42: freqR = `sil;		9'd43: freqR = `sil;
			9'd44: freqR = `sil;		9'd45: freqR = `sil;
			9'd46: freqR = `sil;		9'd47: freqR = `sil;
			9'd48: freqR = `sil;		9'd49: freqR = `sil;
			9'd50: freqR = `sil;		9'd51: freqR = `sil;
			9'd52: freqR = `sil;		9'd53: freqR = `sil;
			9'd54: freqR = `sil;		9'd55: freqR = `sil;
			9'd56: freqR = `sil;		9'd57: freqR = `sil;
			9'd58: freqR = `sil;		9'd59: freqR = `sil;
			9'd60: freqR = `sil;		9'd61: freqR = `sil;
			9'd62: freqR = `sil;		9'd63: freqR = `sil;
			// --- Measure 2 ---
			9'd64: freqR = `bA3;		9'd65: freqR = `bA3;
			9'd66: freqR = `bA3;		9'd67: freqR = `bA3;
			9'd68: freqR = `bA3;		9'd69: freqR = `bA3;
			9'd70: freqR = `bA3;		9'd71: freqR = `sil;
			9'd72: freqR = `bA3;		9'd73: freqR = `bA3;
			9'd74: freqR = `bA3;		9'd75: freqR = `bA3;
			9'd76: freqR = `bA3;		9'd77: freqR = `bA3;
			9'd78: freqR = `bA3;		9'd79: freqR = `sil;
			9'd80: freqR = `bA3;		9'd81: freqR = `bA3;
			9'd82: freqR = `bA3;		9'd83: freqR = `bA3;
			9'd84: freqR = `bA3;		9'd85: freqR = `bA3;
			9'd86: freqR = `bA3;		9'd87: freqR = `bA3;
			9'd88: freqR = `sil;		9'd89: freqR = `sil;
			9'd90: freqR = `sil;		9'd91: freqR = `sil;
			9'd92: freqR = `sil;		9'd93: freqR = `sil;
			9'd94: freqR = `sil;		9'd95: freqR = `sil;
			9'd96: freqR = `sil;		9'd97: freqR = `sil;
			9'd98: freqR = `sil;		9'd99: freqR = `sil;
			9'd100: freqR = `sil;		9'd101: freqR = `sil;
			9'd102: freqR = `sil;		9'd103: freqR = `sil;
			9'd104: freqR = `sil;		9'd105: freqR = `sil;
			9'd106: freqR = `sil;		9'd107: freqR = `sil;
			9'd108: freqR = `sil;		9'd109: freqR = `sil;
			9'd110: freqR = `sil;		9'd111: freqR = `sil;
			9'd112: freqR = `sil;		9'd113: freqR = `sil;
			9'd114: freqR = `sil;		9'd115: freqR = `sil;
			9'd116: freqR = `sil;		9'd117: freqR = `sil;
			9'd118: freqR = `sil;		9'd119: freqR = `sil;
			9'd120: freqR = `_F3;		9'd121: freqR = `_F3;
			9'd122: freqR = `_F3;		9'd123: freqR = `_F3;
			9'd124: freqR = `_F3;		9'd125: freqR = `_F3;
			9'd126: freqR = `_F3;		9'd127: freqR = `_F3;
			// --- Measure 3 ---
			9'd128: freqR = `bG3;		9'd129: freqR = `bG3;
			9'd130: freqR = `bG3;		9'd131: freqR = `bG3;
			9'd132: freqR = `bG3;		9'd133: freqR = `bG3;
			9'd134: freqR = `bG3;		9'd135: freqR = `bG3;
			9'd136: freqR = `bG3;		9'd137: freqR = `bG3;
			9'd138: freqR = `bG3;		9'd139: freqR = `bG3;
			9'd140: freqR = `bG3;		9'd141: freqR = `bG3;
			9'd142: freqR = `bG3;		9'd143: freqR = `bG3;
			9'd144: freqR = `sil;		9'd145: freqR = `sil;
			9'd146: freqR = `sil;		9'd147: freqR = `sil;
			9'd148: freqR = `sil;		9'd149: freqR = `sil;
			9'd150: freqR = `sil;		9'd151: freqR = `sil;
			9'd152: freqR = `sil;		9'd153: freqR = `sil;
			9'd154: freqR = `sil;		9'd155: freqR = `sil;
			9'd156: freqR = `sil;		9'd157: freqR = `sil;
			9'd158: freqR = `sil;		9'd159: freqR = `sil;
			9'd160: freqR = `sil;		9'd161: freqR = `sil;
			9'd162: freqR = `sil;		9'd163: freqR = `sil;
			9'd164: freqR = `sil;		9'd165: freqR = `sil;
			9'd166: freqR = `sil;		9'd167: freqR = `sil;
			9'd168: freqR = `sil;		9'd169: freqR = `sil;
			9'd170: freqR = `sil;		9'd171: freqR = `sil;
			9'd172: freqR = `sil;		9'd173: freqR = `sil;
			9'd174: freqR = `sil;		9'd175: freqR = `sil;
			9'd176: freqR = `sil;		9'd177: freqR = `sil;
			9'd178: freqR = `sil;		9'd179: freqR = `sil;
			9'd180: freqR = `sil;		9'd181: freqR = `sil;
			9'd182: freqR = `sil;		9'd183: freqR = `sil;
			9'd184: freqR = `sil;		9'd185: freqR = `sil;
			9'd186: freqR = `sil;		9'd187: freqR = `sil;
			9'd188: freqR = `sil;		9'd189: freqR = `sil;
			9'd190: freqR = `sil;		9'd191: freqR = `sil;
			// --- Measure 4 ---
			9'd192: freqR = `bA3;		9'd193: freqR = `bA3;
			9'd194: freqR = `bA3;		9'd195: freqR = `bA3;
			9'd196: freqR = `bA3;		9'd197: freqR = `bA3;
			9'd198: freqR = `bA3;		9'd199: freqR = `bA3;
			9'd200: freqR = `bA3;		9'd201: freqR = `bA3;
			9'd202: freqR = `bA3;		9'd203: freqR = `bA3;
			9'd204: freqR = `bA3;		9'd205: freqR = `bA3;
			9'd206: freqR = `bA3;		9'd207: freqR = `bA3;
			9'd208: freqR = `_G3;		9'd209: freqR = `_G3;
			9'd210: freqR = `_G3;		9'd211: freqR = `_G3;
			9'd212: freqR = `_G3;		9'd213: freqR = `_G3;
			9'd214: freqR = `_G3;		9'd215: freqR = `_G3;
			9'd216: freqR = `_G3;		9'd217: freqR = `_G3;
			9'd218: freqR = `_G3;		9'd219: freqR = `_G3;
			9'd220: freqR = `_G3;		9'd221: freqR = `_G3;
			9'd222: freqR = `_G3;		9'd223: freqR = `_G3;
			9'd224: freqR = `bG3;		9'd225: freqR = `bG3;
			9'd226: freqR = `bG3;		9'd227: freqR = `bG3;
			9'd228: freqR = `bG3;		9'd229: freqR = `bG3;
			9'd230: freqR = `bG3;		9'd231: freqR = `bG3;
			9'd232: freqR = `bG3;		9'd233: freqR = `bG3;
			9'd234: freqR = `bG3;		9'd235: freqR = `bG3;
			9'd236: freqR = `bG3;		9'd237: freqR = `bG3;
			9'd238: freqR = `bG3;		9'd239: freqR = `bG3;
			9'd240: freqR = `sil;		9'd241: freqR = `sil;
			9'd242: freqR = `sil;		9'd243: freqR = `sil;
			9'd244: freqR = `sil;		9'd245: freqR = `sil;
			9'd246: freqR = `sil;		9'd247: freqR = `sil;
			9'd248: freqR = `sil;		9'd249: freqR = `sil;
			9'd250: freqR = `sil;		9'd251: freqR = `sil;
			9'd252: freqR = `sil;		9'd253: freqR = `sil;
			9'd254: freqR = `sil;		9'd255: freqR = `sil;
			// --- Measure 5 ---
			9'd256: freqR = `sil;		9'd257: freqR = `sil;
			9'd258: freqR = `sil;		9'd259: freqR = `sil;
			9'd260: freqR = `sil;		9'd261: freqR = `sil;
			9'd262: freqR = `sil;		9'd263: freqR = `sil;
			9'd264: freqR = `sil;		9'd265: freqR = `sil;
			9'd266: freqR = `sil;		9'd267: freqR = `sil;
			9'd268: freqR = `sil;		9'd269: freqR = `sil;
			9'd270: freqR = `sil;		9'd271: freqR = `sil;
			9'd272: freqR = `_E4;		9'd273: freqR = `_E4;
			9'd274: freqR = `_E4;		9'd275: freqR = `_E4;
			9'd276: freqR = `_E4;		9'd277: freqR = `_E4;
			9'd278: freqR = `_E4;		9'd279: freqR = `_E4;
			9'd280: freqR = `sil;		9'd281: freqR = `sil;
			9'd282: freqR = `sil;		9'd283: freqR = `sil;
			9'd284: freqR = `sil;		9'd285: freqR = `sil;
			9'd286: freqR = `sil;		9'd287: freqR = `sil;
			9'd288: freqR = `sil;		9'd289: freqR = `sil;
			9'd290: freqR = `sil;		9'd291: freqR = `sil;
			9'd292: freqR = `sil;		9'd293: freqR = `sil;
			9'd294: freqR = `sil;		9'd295: freqR = `sil;
			9'd296: freqR = `sil;		9'd297: freqR = `sil;
			9'd298: freqR = `sil;		9'd299: freqR = `sil;
			9'd300: freqR = `sil;		9'd301: freqR = `sil;
			9'd302: freqR = `sil;		9'd303: freqR = `sil;
			9'd304: freqR = `sil;		9'd305: freqR = `sil;
			9'd306: freqR = `sil;		9'd307: freqR = `sil;
			9'd308: freqR = `sil;		9'd309: freqR = `sil;
			9'd310: freqR = `sil;		9'd311: freqR = `sil;
			9'd312: freqR = `sil;		9'd313: freqR = `sil;
			9'd314: freqR = `sil;		9'd315: freqR = `sil;
			9'd316: freqR = `sil;		9'd317: freqR = `sil;
			9'd318: freqR = `sil;		9'd319: freqR = `sil;
			// --- Measure 6 ---
			9'd320: freqR = `sil;		9'd321: freqR = `sil;
			9'd322: freqR = `sil;		9'd323: freqR = `sil;
			9'd324: freqR = `sil;		9'd325: freqR = `sil;
			9'd326: freqR = `sil;		9'd327: freqR = `sil;
			9'd328: freqR = `_E4;		9'd329: freqR = `_E4;
			9'd330: freqR = `_E4;		9'd331: freqR = `_E4;
			9'd332: freqR = `_E4;		9'd333: freqR = `_E4;
			9'd334: freqR = `_E4;		9'd335: freqR = `_E4;
			9'd336: freqR = `sil;		9'd337: freqR = `sil;
			9'd338: freqR = `sil;		9'd339: freqR = `sil;
			9'd340: freqR = `sil;		9'd341: freqR = `sil;
			9'd342: freqR = `sil;		9'd343: freqR = `sil;
			9'd344: freqR = `_G3;		9'd345: freqR = `_G3;
			9'd346: freqR = `_G3;		9'd347: freqR = `_G3;
			9'd348: freqR = `_G3;		9'd349: freqR = `_G3;
			9'd350: freqR = `_G3;		9'd351: freqR = `_G3;
			9'd352: freqR = `bG3;		9'd353: freqR = `bG3;
			9'd354: freqR = `bG3;		9'd355: freqR = `bG3;
			9'd356: freqR = `bG3;		9'd357: freqR = `bG3;
			9'd358: freqR = `bG3;		9'd359: freqR = `bG3;
			9'd360: freqR = `sil;		9'd361: freqR = `sil;
			9'd362: freqR = `sil;		9'd363: freqR = `sil;
			9'd364: freqR = `sil;		9'd365: freqR = `sil;
			9'd366: freqR = `sil;		9'd367: freqR = `sil;
			9'd368: freqR = `bD4;		9'd369: freqR = `bD4;
			9'd370: freqR = `bD4;		9'd371: freqR = `bD4;
			9'd372: freqR = `bD4;		9'd373: freqR = `bD4;
			9'd374: freqR = `bD4;		9'd375: freqR = `bD4;
			9'd376: freqR = `sil;		9'd377: freqR = `sil;
			9'd378: freqR = `sil;		9'd379: freqR = `sil;
			9'd380: freqR = `sil;		9'd381: freqR = `sil;
			9'd382: freqR = `sil;		9'd383: freqR = `sil;
			// --- Measure 7 ---
			9'd384: freqR = `bG3;		9'd385: freqR = `bG3;
			9'd386: freqR = `bG3;		9'd387: freqR = `bG3;
			9'd388: freqR = `bG3;		9'd389: freqR = `bG3;
			9'd390: freqR = `bG3;		9'd391: freqR = `sil;
			9'd392: freqR = `bG3;		9'd393: freqR = `bG3;
			9'd394: freqR = `bG3;		9'd395: freqR = `bG3;
			9'd396: freqR = `bG3;		9'd397: freqR = `bG3;
			9'd398: freqR = `bG3;		9'd399: freqR = `sil;
			9'd400: freqR = `bG3;		9'd401: freqR = `bG3;
			9'd402: freqR = `bG3;		9'd403: freqR = `bG3;
			9'd404: freqR = `bG3;		9'd405: freqR = `bG3;
			9'd406: freqR = `bG3;		9'd407: freqR = `bG3;
			9'd408: freqR = `sil;		9'd409: freqR = `sil;
			9'd410: freqR = `sil;		9'd411: freqR = `sil;
			9'd412: freqR = `sil;		9'd413: freqR = `sil;
			9'd414: freqR = `sil;		9'd415: freqR = `sil;
			9'd416: freqR = `sil;		9'd417: freqR = `sil;
			9'd418: freqR = `sil;		9'd419: freqR = `sil;
			9'd420: freqR = `sil;		9'd421: freqR = `sil;
			9'd422: freqR = `sil;		9'd423: freqR = `sil;
			9'd424: freqR = `sil;		9'd425: freqR = `sil;
			9'd426: freqR = `sil;		9'd427: freqR = `sil;
			9'd428: freqR = `sil;		9'd429: freqR = `sil;
			9'd430: freqR = `sil;		9'd431: freqR = `sil;
			9'd432: freqR = `bG3;		9'd433: freqR = `bG3;
			9'd434: freqR = `bG3;		9'd435: freqR = `bG3;
			9'd436: freqR = `bG3;		9'd437: freqR = `bG3;
			9'd438: freqR = `bG3;		9'd439: freqR = `sil;
			9'd440: freqR = `bG3;		9'd441: freqR = `bG3;
			9'd442: freqR = `bG3;		9'd443: freqR = `bG3;
			9'd444: freqR = `bG3;		9'd445: freqR = `bG3;
			9'd446: freqR = `bG3;		9'd447: freqR = `sil;
			// --- Measure 8 ---
			9'd448: freqR = `bG3;		9'd449: freqR = `bG3;
			9'd450: freqR = `bG3;		9'd451: freqR = `bG3;
			9'd452: freqR = `bG3;		9'd453: freqR = `bG3;
			9'd454: freqR = `bG3;		9'd455: freqR = `bG3;
			9'd456: freqR = `sil;		9'd457: freqR = `sil;
			9'd458: freqR = `sil;		9'd459: freqR = `sil;
			9'd460: freqR = `sil;		9'd461: freqR = `sil;
			9'd462: freqR = `sil;		9'd463: freqR = `sil;
			9'd464: freqR = `sil;		9'd465: freqR = `sil;
			9'd466: freqR = `sil;		9'd467: freqR = `sil;
			9'd468: freqR = `sil;		9'd469: freqR = `sil;
			9'd470: freqR = `sil;		9'd471: freqR = `sil;
			9'd472: freqR = `sil;		9'd473: freqR = `sil;
			9'd474: freqR = `sil;		9'd475: freqR = `sil;
			9'd476: freqR = `sil;		9'd477: freqR = `sil;
			9'd478: freqR = `sil;		9'd479: freqR = `sil;
			9'd480: freqR = `sil;		9'd481: freqR = `sil;
			9'd482: freqR = `sil;		9'd483: freqR = `sil;
			9'd484: freqR = `sil;		9'd485: freqR = `sil;
			9'd486: freqR = `sil;		9'd487: freqR = `sil;
			9'd488: freqR = `sil;		9'd489: freqR = `sil;
			9'd490: freqR = `sil;		9'd491: freqR = `sil;
			9'd492: freqR = `sil;		9'd493: freqR = `sil;
			9'd494: freqR = `sil;		9'd495: freqR = `sil;
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

module music1(
    input [3:0] beat,
    output reg [31:0] freqL,
    output reg [31:0] freqR
    );

	always @* begin
		case(beat)
			// --- Measure 1 ---
			4'd0: freqL = `_C6;		4'd1: freqL = `_C6;
			4'd2: freqL = `_C6;		4'd3: freqL = `_C6;
			4'd4: freqL = `_E6;		4'd5: freqL = `_E6;
			4'd6: freqL = `_E6;		4'd7: freqL = `_E6;
			4'd8: freqL = `_E6;		4'd9: freqL = `_E6;
			4'd10: freqL = `_E6;		4'd11: freqL = `_E6;
			4'd12: freqL = `_E6;		4'd13: freqL = `_E6;
			4'd14: freqL = `_E6;		4'd15: freqL = `_E6;
		endcase
	end
	always @* begin
		case(beat)
			// --- Measure 1 ---
			4'd0: freqR = `_C6;		4'd1: freqR = `_C6;
			4'd2: freqR = `_C6;		4'd3: freqR = `_C6;
			4'd4: freqR = `_E6;		4'd5: freqR = `_E6;
			4'd6: freqR = `_E6;		4'd7: freqR = `_E6;
			4'd8: freqR = `_E6;		4'd9: freqR = `_E6;
			4'd10: freqR = `_E6;		4'd11: freqR = `_E6;
			4'd12: freqR = `_E6;		4'd13: freqR = `_E6;
			4'd14: freqR = `_E6;		4'd15: freqR = `_E6;
		endcase
	end



endmodule

module music2(
    input [3:0] beat,
    output reg [31:0] freqL,
    output reg [31:0] freqR
    );
	always @* begin
		case(beat)
			// --- Measure 1 ---
			4'd0: freqL = `_D3;		4'd1: freqL = `_D3;
			4'd2: freqL = `bE3;		4'd3: freqL = `bE3;
			4'd4: freqL = `_E3;		4'd5: freqL = `_E3;
			4'd6: freqL = `_F3;		4'd7: freqL = `_F3;
			4'd8: freqL = `bG3;		4'd9: freqL = `bG3;
			4'd10: freqL = `_G3;		4'd11: freqL = `_G3;
			4'd12: freqL = `bA3;		4'd13: freqL = `bA3;
			4'd14: freqL = `_A3;		4'd15: freqL = `_A3;
		endcase
	end
	always @* begin
		case(beat)
			// --- Measure 1 ---
			4'd0: freqR = `_D3;		4'd1: freqR = `_D3;
			4'd2: freqR = `bE3;		4'd3: freqR = `bE3;
			4'd4: freqR = `_E3;		4'd5: freqR = `_E3;
			4'd6: freqR = `_F3;		4'd7: freqR = `_F3;
			4'd8: freqR = `bG3;		4'd9: freqR = `bG3;
			4'd10: freqR = `_G3;		4'd11: freqR = `_G3;
			4'd12: freqR = `bA3;		4'd13: freqR = `bA3;
			4'd14: freqR = `_A3;		4'd15: freqR = `_A3;
		endcase
	end

endmodule

module music3(
    input [6:0] beat,
    output reg [31:0] freqL,
    output reg [31:0] freqR
    );
	always @* begin
		case(beat)
			// --- Measure 1 ---
			7'd0: freqL = `_G4;		7'd1: freqL = `_G4;
			7'd2: freqL = `_C5;		7'd3: freqL = `_C5;
			7'd4: freqL = `_E5;		7'd5: freqL = `_E5;
			7'd6: freqL = `_G5;		7'd7: freqL = `_G5;
			7'd8: freqL = `_C6;		7'd9: freqL = `_C6;
			7'd10: freqL = `_E6;		7'd11: freqL = `_E6;
			7'd12: freqL = `_G6;		7'd13: freqL = `_G6;
			7'd14: freqL = `_G6;		7'd15: freqL = `_G6;
			7'd16: freqL = `_G6;		7'd17: freqL = `_G6;
			7'd18: freqL = `_E6;		7'd19: freqL = `_E6;
			7'd20: freqL = `_E6;		7'd21: freqL = `_E6;
			7'd22: freqL = `_E6;		7'd23: freqL = `_E6;
			7'd24: freqL = `bA4;		7'd25: freqL = `bA4;
			7'd26: freqL = `_C5;		7'd27: freqL = `_C5;
			7'd28: freqL = `bE5;		7'd29: freqL = `bE5;
			7'd30: freqL = `bA5;		7'd31: freqL = `bA5;
			7'd32: freqL = `_C6;		7'd33: freqL = `_C6;
			7'd34: freqL = `bE6;		7'd35: freqL = `bE6;
			7'd36: freqL = `bA6;		7'd37: freqL = `bA6;
			7'd38: freqL = `bA6;		7'd39: freqL = `bA6;
			7'd40: freqL = `bA6;		7'd41: freqL = `bA6;
			7'd42: freqL = `_E6;		7'd43: freqL = `_E6;
			7'd44: freqL = `_E6;		7'd45: freqL = `_E6;
			7'd46: freqL = `_E6;		7'd47: freqL = `_E6;
			7'd48: freqL = `bB4;		7'd49: freqL = `bB4;
			7'd50: freqL = `_D5;		7'd51: freqL = `_D5;
			7'd52: freqL = `_F5;		7'd53: freqL = `_F5;
			7'd54: freqL = `bB5;		7'd55: freqL = `bB5;
			7'd56: freqL = `_D6;		7'd57: freqL = `_D6;
			7'd58: freqL = `_F6;		7'd59: freqL = `_F6;
			7'd60: freqL = `bB6;		7'd61: freqL = `bB6;
			7'd62: freqL = `bB6;		7'd63: freqL = `bB6;
			// --- Measure 2 ---
			7'd64: freqL = `bB6;		7'd65: freqL = `bB6;
			7'd66: freqL = `_B6;		7'd67: freqL = `sil;
			7'd68: freqL = `_B6;		7'd69: freqL = `sil;
			7'd70: freqL = `_B6;		7'd71: freqL = `_B6;
			7'd72: freqL = `_C7;		7'd73: freqL = `_C7;
			7'd74: freqL = `_C7;		7'd75: freqL = `_C7;
			7'd76: freqL = `_C7;		7'd77: freqL = `_C7;
			7'd78: freqL = `_C7;		7'd79: freqL = `_C7;
			7'd80: freqL = `_C7;		7'd81: freqL = `_C7;
			7'd82: freqL = `_C7;		7'd83: freqL = `_C7;
			7'd84: freqL = `_C7;		7'd85: freqL = `_C7;
			7'd86: freqL = `_C7;		7'd87: freqL = `_C7;
			7'd88: freqL = `_C7;		7'd89: freqL = `_C7;
			7'd90: freqL = `_C7;		7'd91: freqL = `_C7;
			7'd92: freqL = `_C7;		7'd93: freqL = `_C7;
			7'd94: freqL = `_C7;		7'd95: freqL = `_C7;
			7'd96: freqL = `sil;		7'd97: freqL = `sil;
			7'd98: freqL = `sil;		7'd99: freqL = `sil;
			7'd100: freqL = `sil;		7'd101: freqL = `sil;
			7'd102: freqL = `sil;		7'd103: freqL = `sil;
			7'd104: freqL = `sil;		7'd105: freqL = `sil;
			7'd106: freqL = `_B6;		7'd107: freqL = `_B6;
			7'd108: freqL = `_B6;		7'd109: freqL = `_B6;
			7'd110: freqL = `_B6;		7'd111: freqL = `sil;
			7'd112: freqL = `_B6;		7'd113: freqL = `_B6;
			7'd114: freqL = `_B6;		7'd115: freqL = `_B6;
			7'd116: freqL = `_B6;		7'd117: freqL = `_B6;
			7'd118: freqL = `sil;		7'd119: freqL = `sil;
			7'd120: freqL = `sil;		7'd121: freqL = `sil;
			7'd122: freqL = `sil;		7'd123: freqL = `sil;
			7'd124: freqL = `sil;		7'd125: freqL = `sil;
			7'd126: freqL = `sil;		7'd127: freqL = `sil;
		endcase
	end
	always @* begin
		case(beat)
			// --- Measure 1 ---
			7'd0: freqR = `_G4;		7'd1: freqR = `_G4;
			7'd2: freqR = `_C5;		7'd3: freqR = `_C5;
			7'd4: freqR = `_E5;		7'd5: freqR = `_E5;
			7'd6: freqR = `_G5;		7'd7: freqR = `_G5;
			7'd8: freqR = `_C6;		7'd9: freqR = `_C6;
			7'd10: freqR = `_E6;		7'd11: freqR = `_E6;
			7'd12: freqR = `_G6;		7'd13: freqR = `_G6;
			7'd14: freqR = `_G6;		7'd15: freqR = `_G6;
			7'd16: freqR = `_G6;		7'd17: freqR = `_G6;
			7'd18: freqR = `_E6;		7'd19: freqR = `_E6;
			7'd20: freqR = `_E6;		7'd21: freqR = `_E6;
			7'd22: freqR = `_E6;		7'd23: freqR = `_E6;
			7'd24: freqR = `bA4;		7'd25: freqR = `bA4;
			7'd26: freqR = `_C5;		7'd27: freqR = `_C5;
			7'd28: freqR = `bE5;		7'd29: freqR = `bE5;
			7'd30: freqR = `bA5;		7'd31: freqR = `bA5;
			7'd32: freqR = `_C6;		7'd33: freqR = `_C6;
			7'd34: freqR = `bE6;		7'd35: freqR = `bE6;
			7'd36: freqR = `bA6;		7'd37: freqR = `bA6;
			7'd38: freqR = `bA6;		7'd39: freqR = `bA6;
			7'd40: freqR = `bA6;		7'd41: freqR = `bA6;
			7'd42: freqR = `_E6;		7'd43: freqR = `_E6;
			7'd44: freqR = `_E6;		7'd45: freqR = `_E6;
			7'd46: freqR = `_E6;		7'd47: freqR = `_E6;
			7'd48: freqR = `bB4;		7'd49: freqR = `bB4;
			7'd50: freqR = `_D5;		7'd51: freqR = `_D5;
			7'd52: freqR = `_F5;		7'd53: freqR = `_F5;
			7'd54: freqR = `bB5;		7'd55: freqR = `bB5;
			7'd56: freqR = `_D6;		7'd57: freqR = `_D6;
			7'd58: freqR = `_F6;		7'd59: freqR = `_F6;
			7'd60: freqR = `bB6;		7'd61: freqR = `bB6;
			7'd62: freqR = `bB6;		7'd63: freqR = `bB6;
			// --- Measure 2 ---
			7'd64: freqR = `bB6;		7'd65: freqR = `bB6;
			7'd66: freqR = `_B6;		7'd67: freqR = `sil;
			7'd68: freqR = `_B6;		7'd69: freqR = `sil;
			7'd70: freqR = `_B6;		7'd71: freqR = `_B6;
			7'd72: freqR = `_C7;		7'd73: freqR = `_C7;
			7'd74: freqR = `_C7;		7'd75: freqR = `_C7;
			7'd76: freqR = `_C7;		7'd77: freqR = `_C7;
			7'd78: freqR = `_C7;		7'd79: freqR = `_C7;
			7'd80: freqR = `_C7;		7'd81: freqR = `_C7;
			7'd82: freqR = `_C7;		7'd83: freqR = `_C7;
			7'd84: freqR = `_C7;		7'd85: freqR = `_C7;
			7'd86: freqR = `_C7;		7'd87: freqR = `_C7;
			7'd88: freqR = `_C7;		7'd89: freqR = `_C7;
			7'd90: freqR = `_C7;		7'd91: freqR = `_C7;
			7'd92: freqR = `_C7;		7'd93: freqR = `_C7;
			7'd94: freqR = `_C7;		7'd95: freqR = `_C7;
			7'd96: freqR = `sil;		7'd97: freqR = `sil;
			7'd98: freqR = `sil;		7'd99: freqR = `sil;
			7'd100: freqR = `sil;		7'd101: freqR = `sil;
			7'd102: freqR = `sil;		7'd103: freqR = `sil;
			7'd104: freqR = `sil;		7'd105: freqR = `sil;
			7'd106: freqR = `_B6;		7'd107: freqR = `_B6;
			7'd108: freqR = `_B6;		7'd109: freqR = `_B6;
			7'd110: freqR = `_B6;		7'd111: freqR = `sil;
			7'd112: freqR = `_B6;		7'd113: freqR = `_B6;
			7'd114: freqR = `_B6;		7'd115: freqR = `_B6;
			7'd116: freqR = `_B6;		7'd117: freqR = `_B6;
			7'd118: freqR = `sil;		7'd119: freqR = `sil;
			7'd120: freqR = `sil;		7'd121: freqR = `sil;
			7'd122: freqR = `sil;		7'd123: freqR = `sil;
			7'd124: freqR = `sil;		7'd125: freqR = `sil;
			7'd126: freqR = `sil;		7'd127: freqR = `sil;
		endcase
	end

endmodule

module Random(
    input clk, 
    input rst,
    output [6:0] out
    );
     
     reg [20:0] rand;
     reg [20:0] next_rand;
     wire feed;
     
     assign feed = rand[20] ^ rand[17];
     assign out = rand[6:0];

     always @ (posedge clk, posedge rst)
     begin
        if(rst)begin
           rand <= ~(20'b0);
        end
        else begin
           rand <= next_rand;
           
        end
        
     end
     
     always @ (*)
     begin
        next_rand = {rand[19:0], feed};
     end
endmodule

module clock_divider #(parameter n=25)(
    input rst,
    input clk,
    output reg clk_div
);
 
    reg [n-1:0] num;
    reg [n-1:0] next_num;
 
    always @(posedge clk, posedge rst) begin
        if(rst)begin
            num <= 0;
        end
        else begin
            num <= next_num;
        end
       
    end
   
    always @(*) begin
        next_num = num + 1;
        clk_div = num[n-1];
    end
 
endmodule
 
`timescale 1ns/1ps
/////////////////////////////////////////////////////////////////
// Module Name: vga
/////////////////////////////////////////////////////////////////

module vga_controller (
    input wire pclk, reset,
    output wire hsync, vsync, valid,
    output wire [9:0]h_cnt,
    output wire [9:0]v_cnt
    );

    reg [9:0]pixel_cnt;
    reg [9:0]line_cnt;
    reg hsync_i,vsync_i;

    parameter HD = 640;
    parameter HF = 16;
    parameter HS = 96;
    parameter HB = 48;
    parameter HT = 800; 
    parameter VD = 480;
    parameter VF = 10;
    parameter VS = 2;
    parameter VB = 33;
    parameter VT = 525;
    parameter hsync_default = 1'b1;
    parameter vsync_default = 1'b1;

    always @(posedge pclk)
        if (reset)
            pixel_cnt <= 0;
        else
            if (pixel_cnt < (HT - 1))
                pixel_cnt <= pixel_cnt + 1;
            else
                pixel_cnt <= 0;

    always @(posedge pclk)
        if (reset)
            hsync_i <= hsync_default;
        else
            if ((pixel_cnt >= (HD + HF - 1)) && (pixel_cnt < (HD + HF + HS - 1)))
                hsync_i <= ~hsync_default;
            else
                hsync_i <= hsync_default; 

    always @(posedge pclk)
        if (reset)
            line_cnt <= 0;
        else
            if (pixel_cnt == (HT -1))
                if (line_cnt < (VT - 1))
                    line_cnt <= line_cnt + 1;
                else
                    line_cnt <= 0;

    always @(posedge pclk)
        if (reset)
            vsync_i <= vsync_default; 
        else if ((line_cnt >= (VD + VF - 1)) && (line_cnt < (VD + VF + VS - 1)))
            vsync_i <= ~vsync_default; 
        else
            vsync_i <= vsync_default; 

    assign hsync = hsync_i;
    assign vsync = vsync_i;
    assign valid = ((pixel_cnt < HD) && (line_cnt < VD));

    assign h_cnt = (pixel_cnt < HD) ? pixel_cnt : 10'd0;
    assign v_cnt = (line_cnt < VD) ? line_cnt : 10'd0;

endmodule

module OnePulse (
	output reg signal_single_pulse,
	input wire signal,
	input wire clock
	);
	
	reg signal_delay;

	always @(posedge clock) begin
		if (signal == 1'b1 & signal_delay == 1'b0)
		  signal_single_pulse <= 1'b1;
		else
		  signal_single_pulse <= 1'b0;

		signal_delay <= signal;
	end
endmodule

module KeyboardDecoder(
	output reg [511:0] key_down,
	output wire [8:0] last_change,
	output reg key_valid,
	inout wire PS2_DATA,
	inout wire PS2_CLK,
	input wire rst,
	input wire clk
    );
    
    parameter [1:0] INIT			= 2'b00;
    parameter [1:0] WAIT_FOR_SIGNAL = 2'b01;
    parameter [1:0] GET_SIGNAL_DOWN = 2'b10;
    parameter [1:0] WAIT_RELEASE    = 2'b11;
    
	parameter [7:0] IS_INIT			= 8'hAA;
    parameter [7:0] IS_EXTEND		= 8'hE0;
    parameter [7:0] IS_BREAK		= 8'hF0;
    
    reg [9:0] key;		// key = {been_extend, been_break, key_in}
    reg [1:0] state;
    reg been_ready, been_extend, been_break;
    
    wire [7:0] key_in;
    wire is_extend;
    wire is_break;
    wire valid;
    wire err;
    
    wire [511:0] key_decode = 1 << last_change;
    assign last_change = {key[9], key[7:0]};
    
    KeyboardCtrl inst (
		.key_in(key_in),
		.is_extend(is_extend),
		.is_break(is_break),
		.valid(valid),
		.err(err),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
	
	OnePulse op (
		.signal_single_pulse(pulse_been_ready),
		.signal(been_ready),
		.clock(clk)
	);
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		state <= INIT;
    		been_ready  <= 1'b0;
    		been_extend <= 1'b0;
    		been_break  <= 1'b0;
    		key <= 10'b0_0_0000_0000;
    	end else begin
    		state <= state;
			been_ready  <= been_ready;
			been_extend <= (is_extend) ? 1'b1 : been_extend;
			been_break  <= (is_break ) ? 1'b1 : been_break;
			key <= key;
    		case (state)
    			INIT : begin
    					if (key_in == IS_INIT) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready  <= 1'b0;
							been_extend <= 1'b0;
							been_break  <= 1'b0;
							key <= 10'b0_0_0000_0000;
    					end else begin
    						state <= INIT;
    					end
    				end
    			WAIT_FOR_SIGNAL : begin
    					if (valid == 0) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready <= 1'b0;
    					end else begin
    						state <= GET_SIGNAL_DOWN;
    					end
    				end
    			GET_SIGNAL_DOWN : begin
						state <= WAIT_RELEASE;
						key <= {been_extend, been_break, key_in};
						been_ready  <= 1'b1;
    				end
    			WAIT_RELEASE : begin
    					if (valid == 1) begin
    						state <= WAIT_RELEASE;
    					end else begin
    						state <= WAIT_FOR_SIGNAL;
    						been_extend <= 1'b0;
    						been_break  <= 1'b0;
    					end
    				end
    			default : begin
    					state <= INIT;
						been_ready  <= 1'b0;
						been_extend <= 1'b0;
						been_break  <= 1'b0;
						key <= 10'b0_0_0000_0000;
    				end
    		endcase
    	end
    end
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		key_valid <= 1'b0;
    		key_down <= 511'b0;
    	end else if (key_decode[last_change] && pulse_been_ready) begin
    		key_valid <= 1'b1;
    		if (key[8] == 0) begin
    			key_down <= key_down | key_decode;
    		end else begin
    			key_down <= key_down & (~key_decode);
    		end
    	end else begin
    		key_valid <= 1'b0;
			key_down <= key_down;
    	end
    end

endmodule
