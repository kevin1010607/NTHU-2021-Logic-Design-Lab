`timescale 1ns / 100ps

module seven_segment_display (
    input clk,
    input [3:0] number_0,
    input [3:0] number_1,
    input [3:0] number_2,
    input [3:0] number_3,
    output reg [3:0] digit,
    output reg [6:0] display
);
  wire clk_seg;
  wire [3:0] next_digit;
  reg [3:0] display_number;

  clock_divider_2_square #(
      .n(18)
  ) clock_divider_seg (
      .clk(clk),
      .clk_div(clk_seg)
  );

  assign next_digit = digit ? {digit[2:0], digit[3]} : 4'b1110;

  always @(posedge clk_seg) begin
    digit <= next_digit;
  end

  always @* begin
    case (digit)
      4'b1110: display_number = number_0;
      4'b1101: display_number = number_1;
      4'b1011: display_number = number_2;
      4'b0111: display_number = number_3;
      default: display_number = 4'd15;
    endcase
  end

  always @* begin
    case (display_number)  // gfedcba
      4'd0: display    = 7'b1000000;
      4'd1: display    = 7'b1111001;
      4'd2: display    = 7'b0100100;
      4'd3: display    = 7'b0110000;
      4'd4: display    = 7'b0011001;
      4'd5: display    = 7'b0010010;
      4'd6: display    = 7'b0000010;
      4'd7: display    = 7'b1111000;
      4'd8: display    = 7'b0000000;
      4'd9: display    = 7'b0010000;
      4'd10: display   = 7'b0001000; // A
      4'd11: display   = 7'b0010010; // S
      4'd12: display   = 7'b1000110; // C
      4'd15: display   = 7'b1111111;
      default: display = 7'b0111111; // ERROR
    endcase
  end
endmodule



module lab5 (
    input clk,
    input rst,
    input BTNL,
    input BTNR,
    input BTNU,
    input BTND,
    input BTNC,
    output [15:0] LED,
    output [3:0] DIGIT,
    output [6:0] DISPLAY
);

  integer i;

  //
  // clk div
  //

  localparam clk_div_by_2_square = 4;
  wire clk_div;
  clock_divider_2_square #(
      .n(clk_div_by_2_square)
  ) clock_divider_2_square_clk_div (
      .clk(clk),
      .clk_div(clk_div)
  );

  //
  // button input
  //

  wire BTNL_debounced, BTNR_debounced, BTNU_debounced, BTND_debounced, BTNC_debounced;
  wire BTNL_one_pulse, BTNR_one_pulse, BTNU_one_pulse, BTND_one_pulse, BTNC_one_pulse;

  debounce #(
      .n(40)
  ) debounce_BTNL (
      .clk(clk_div),
      .pb_in(BTNL),
      .pb_out(BTNL_debounced)
  );
  debounce #(
      .n(40)
  ) debounce_BTNR (
      .clk(clk_div),
      .pb_in(BTNR),
      .pb_out(BTNR_debounced)
  );
  debounce #(
      .n(40)
  ) debounce_BTNU (
      .clk(clk_div),
      .pb_in(BTNU),
      .pb_out(BTNU_debounced)
  );
  debounce #(
      .n(40)
  ) debounce_BTND (
      .clk(clk_div),
      .pb_in(BTND),
      .pb_out(BTND_debounced)
  );
  debounce #(
      .n(40)
  ) debounce_BTNC (
      .clk(clk_div),
      .pb_in(BTNC),
      .pb_out(BTNC_debounced)
  );

  one_pulse one_pulse_BTNL (
      .clk(clk_div),
      .pb_in(BTNL_debounced),
      .pb_out(BTNL_one_pulse)
  );
  one_pulse one_pulse_BTNR (
      .clk(clk_div),
      .pb_in(BTNR_debounced),
      .pb_out(BTNR_one_pulse)
  );
  one_pulse one_pulse_BTNU (
      .clk(clk_div),
      .pb_in(BTNU_debounced),
      .pb_out(BTNU_one_pulse)
  );
  one_pulse one_pulse_BTND (
      .clk(clk_div),
      .pb_in(BTND_debounced),
      .pb_out(BTND_one_pulse)
  );
  one_pulse one_pulse_BTNC (
      .clk(clk_div),
      .pb_in(BTNC_debounced),
      .pb_out(BTNC_one_pulse)
  );

  //
  // seven segment display
  //

  reg [3:0] display_number[3:0];
  reg [3:0] display_number_next[3:0];

  seven_segment_display seven_segment_display_inst (
      .clk(clk),
      .number_0(display_number[0]),
      .number_1(display_number[1]),
      .number_2(display_number[2]),
      .number_3(display_number[3]),
      .digit(DIGIT),
      .display(DISPLAY)
  );

  //
  // led
  //

  reg led;
  reg led_next;

  assign LED = {16{led}};

  //
  // FSM
  //

  parameter IDLE = 3'd0;
  parameter TYPE = 3'd1;
  parameter AMOUNT = 3'd2;
  parameter PAYMENT = 3'd3;
  parameter RELEASE = 3'd4;
  parameter CHANGE = 3'd5;

  parameter TICKET_TYPE_ADULT = 2'd0;
  parameter TICKET_TYPE_STUDENT = 2'd1;
  parameter TICKET_TYPE_CHILD = 2'd2;

  parameter TICKET_PRICE_ADULT = 4'd15;
  parameter TICKET_PRICE_STUDENT = 4'd10;
  parameter TICKET_PRICE_CHILD = 4'd5;

  reg [2:0] state = 0;
  reg [2:0] state_next;

  reg [1:0] ticket_type = 0;
  reg [1:0] ticket_type_next;

  reg [1:0] ticket_amount = 0;
  reg [1:0] ticket_amount_next;

  reg [6:0] inserted_money = 0;
  reg [6:0] inserted_money_next = 0;

  reg [6:0] price;

  parameter sec = 100000000 / (2 ** clk_div_by_2_square) - 1;

  reg [31:0] counter;
  reg [31:0] counter_next;

  always @(posedge clk_div, posedge rst) begin
    if (rst == 1) begin
      state <= IDLE;
      ticket_type <= TICKET_TYPE_ADULT;
      ticket_amount <= 1;
      inserted_money <= 0;
      counter <= 0;
      for (i = 0; i < 4; i = i + 1) begin
        display_number[i] <= 0;
      end
      led <= 0;
    end else begin
      state <= state_next;
      ticket_type <= ticket_type_next;
      ticket_amount <= ticket_amount_next;
      inserted_money <= inserted_money_next;
      counter <= counter_next;
      for (i = 0; i < 4; i = i + 1) begin
        display_number[i] <= display_number_next[i];
      end
      led <= led_next;
    end
  end

  always @* begin
    case (state)
      default: begin
        state_next = IDLE;
        ticket_type_next = 0;
        ticket_amount_next = 1;
        inserted_money_next = 0;
        for (i = 0; i < 4; i = i + 1) begin
          display_number_next[i] = 4'd15;
        end
        led_next = 0;
      end
      IDLE: begin
        if (BTNL_one_pulse || BTNR_one_pulse || BTNU_one_pulse || BTND_one_pulse || BTNC_one_pulse) begin
          state_next = TYPE;
        end else begin
          state_next = state;
        end

        if (BTNL_one_pulse) begin
          ticket_type_next = TICKET_TYPE_CHILD;
        end else if (BTNC_one_pulse) begin
          ticket_type_next = TICKET_TYPE_STUDENT;
        end else if (BTNR_one_pulse) begin
          ticket_type_next = TICKET_TYPE_ADULT;
        end else begin
          ticket_type_next = ticket_type;
        end

        ticket_amount_next = 1;
        inserted_money_next  = 0;

        for (i = 0; i < 4; i = i + 1) begin
          if (counter % sec == 0) begin
            display_number_next[i] = display_number[i] == 4'd14 ? 4'd15 : 4'd14;
          end else begin
            display_number_next[i] = display_number[i];
          end
        end

        if (counter % sec == 0) begin
          led_next = ~led;
        end else begin
          led_next = led;
        end
      end
      TYPE: begin
        if (BTNU_one_pulse) begin
          state_next = AMOUNT;
        end else if (BTND_one_pulse) begin
          state_next = IDLE;
        end else begin
          state_next = state;
        end

        if (BTNL_one_pulse) begin
          ticket_type_next = TICKET_TYPE_CHILD;
        end else if (BTNC_one_pulse) begin
          ticket_type_next = TICKET_TYPE_STUDENT;
        end else if (BTNR_one_pulse) begin
          ticket_type_next = TICKET_TYPE_ADULT;
        end else begin
          ticket_type_next = ticket_type;
        end

        ticket_amount_next = 1;
        inserted_money_next = 0;

        display_number_next[0] = price % 10;
        display_number_next[1] = price / 10;
        display_number_next[2] = 4'd15;
        display_number_next[3] = 10 + ticket_type;

        led_next = 0;
      end
      AMOUNT: begin
        if (BTNU_one_pulse) begin
          state_next = PAYMENT;
        end else if (BTND_one_pulse) begin
          state_next = IDLE;
        end else begin
          state_next = state;
        end

        ticket_type_next = ticket_type;

        if (BTNL_one_pulse) begin
          ticket_amount_next = ticket_amount > 1 ? ticket_amount - 1 : ticket_amount;
        end else if (BTNR_one_pulse) begin
          ticket_amount_next = ticket_amount < 3 ? ticket_amount + 1 : ticket_amount;
        end else begin
          ticket_amount_next = ticket_amount != 0 ? ticket_amount : 1;
        end

        inserted_money_next = 0;

        display_number_next[0] = ticket_amount % 10;
        display_number_next[1] = 4'd15;
        display_number_next[2] = 4'd15;
        display_number_next[3] = 10 + ticket_type;

        led_next = 0;
      end
      PAYMENT: begin
        if (inserted_money >= price) begin
          state_next = RELEASE;
        end else if (BTND_one_pulse) begin
          state_next = CHANGE;
        end else begin
          state_next = state;
        end

        ticket_type_next = ticket_type;
        if (BTND_one_pulse) begin
          ticket_amount_next = 0;
        end else begin
          ticket_amount_next = ticket_amount;
        end

        if (BTNL_one_pulse) begin
          inserted_money_next = inserted_money + 1;
        end else if (BTNC_one_pulse) begin
          inserted_money_next = inserted_money + 5;
        end else if (BTNR_one_pulse) begin
          inserted_money_next = inserted_money + 10;
        end else begin
          inserted_money_next = inserted_money;
        end

        display_number_next[0] = price % 10;
        display_number_next[1] = price / 10;
        display_number_next[2] = inserted_money % 10;
        display_number_next[3] = inserted_money / 10;

        led_next = 0;
      end
      RELEASE: begin
        if (counter == sec * 5) begin
          state_next = CHANGE;
        end else begin
          state_next = state;
        end

        ticket_type_next = ticket_type;
        ticket_amount_next = ticket_amount;
        inserted_money_next = inserted_money;

        display_number_next[0] = ticket_amount % 10;
        display_number_next[1] = 4'd15;
        display_number_next[2] = 4'd15;
        display_number_next[3] = 10 + ticket_type;

        if (counter % sec == 0) begin
          led_next = ~led;
        end else begin
          led_next = led;
        end
      end
      CHANGE: begin
        if (inserted_money - price == 0 && counter != 0 && counter % sec == 0) begin
          state_next = IDLE;
        end else begin
          state_next = state;
        end

        ticket_type_next = ticket_type;
        ticket_amount_next = ticket_amount;

        if (counter % sec == 0 && counter != 0) begin
          if (inserted_money - price >= 10) begin
            inserted_money_next = inserted_money - 10;
          end else if (inserted_money - price >= 5) begin
            inserted_money_next = inserted_money - 5;
          end else if (inserted_money - price >= 1) begin
            inserted_money_next = inserted_money - 1;
          end else begin
            inserted_money_next = inserted_money;
          end
        end else begin
          inserted_money_next = inserted_money;
        end

        display_number_next[0] = (inserted_money - price) % 10;
        display_number_next[1] = (inserted_money - price) / 10;
        display_number_next[2] = 4'd15;
        display_number_next[3] = 4'd15;

        led_next = 0;
      end
    endcase

    if (state != state_next) begin
      counter_next = 0;
    end else begin
      counter_next = counter + 1;
    end
  end

  always @* begin
    case (ticket_type)
      TICKET_TYPE_ADULT: price = ticket_amount * TICKET_PRICE_ADULT;
      TICKET_TYPE_STUDENT: price = ticket_amount * TICKET_PRICE_STUDENT;
      TICKET_TYPE_CHILD: price = ticket_amount * TICKET_PRICE_CHILD;
      default: price = 0;
    endcase
  end

endmodule
