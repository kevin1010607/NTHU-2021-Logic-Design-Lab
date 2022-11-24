module Lab9(
    input clk,
    input rst,
    input echo,
    input left_track,
    input right_track,
    input mid_track,
    output trig,
    output IN1,
    output IN2,
    output IN3, 
    output IN4,
    output left_pwm,
    output right_pwm
    // You may modify or add more input/ouput yourself.
);
    // We have connected the motor, tracker_sensor and sonic_top modules in the template file for you.
    // TODO: control the motors with the information you get from ultrasonic sensor and 3-way track sensor.

    reg [1:0] mode;
    wire [19:0] distance;
    wire [1:0] tracker_state;
    
    motor A(
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .pwm({left_pwm, right_pwm}),
        .l_IN({IN1, IN2}),
        .r_IN({IN3, IN4})
    );

    sonic_top B(
        .clk(clk), 
        .rst(rst), 
        .Echo(echo), 
        .Trig(trig),
        .distance(distance)
    );

    tracker_sensor C(
        .clk(clk), 
        .reset(rst), 
        .left_track(~left_track), 
        .right_track(~right_track),
        .mid_track(~mid_track), 
        .state(tracker_state)
    );

endmodule