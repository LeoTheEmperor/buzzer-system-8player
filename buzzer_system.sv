module buzzer_system(
    input wire clk,
    input wire rst,
    input wire [7:0] buzzers,
    input wire start_round,
    input wire enable_timer,
    input wire [3:0] time_limit,
    output reg [7:0] player_led,
    output reg locked,
    output reg [2:0] winner_id,
    output reg [7:0] scores [0:7],
    output reg buzzer_sound,
    output reg [6:0] seg_display,
    output reg [3:0] seg_select,
    output reg time_expired,
    output reg round_active
);

    localparam IDLE = 3'b000;
    localparam WAITING = 3'b001;
    localparam LOCKED = 3'b010;
    localparam TIME_OUT = 3'b011;
    localparam SCORING = 3'b100;
    
    reg [2:0] state;
    reg [25:0] timer_counter;
    reg [3:0] seconds_remaining;
    reg [15:0] sound_counter;
    reg [1:0] display_digit;
    reg [15:0] display_refresh;
    
    always @(*) begin
        if (buzzers[0])
            winner_id = 3'd0;
        else if (buzzers[1])
            winner_id = 3'd1;
        else if (buzzers[2])
            winner_id = 3'd2;
        else if (buzzers[3])
            winner_id = 3'd3;
        else if (buzzers[4])
            winner_id = 3'd4;
        else if (buzzers[5])
            winner_id = 3'd5;
        else if (buzzers[6])
            winner_id = 3'd6;
        else if (buzzers[7])
            winner_id = 3'd7;
        else
            winner_id = 3'd0;
    end
    
    function [6:0] seg_decode;
        input [3:0] digit;
        begin
            case(digit)
                4'd0: seg_decode = 7'b0111111;
                4'd1: seg_decode = 7'b0000110;
                4'd2: seg_decode = 7'b1011011;
                4'd3: seg_decode = 7'b1001111;
                4'd4: seg_decode = 7'b1100110;
                4'd5: seg_decode = 7'b1101101;
                4'd6: seg_decode = 7'b1111101;
                4'd7: seg_decode = 7'b0000111;
                4'd8: seg_decode = 7'b1111111;
                4'd9: seg_decode = 7'b1101111;
                default: seg_decode = 7'b0000000;
            endcase
        end
    endfunction
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            player_led <= 8'b00000000;
            locked <= 1'b0;
            timer_counter <= 26'd0;
            seconds_remaining <= 4'd0;
            time_expired <= 1'b0;
            round_active <= 1'b0;
            buzzer_sound <= 1'b0;
            sound_counter <= 16'd0;
            
            scores[0] <= 8'd0;
            scores[1] <= 8'd0;
            scores[2] <= 8'd0;
            scores[3] <= 8'd0;
            scores[4] <= 8'd0;
            scores[5] <= 8'd0;
            scores[6] <= 8'd0;
            scores[7] <= 8'd0;
        end
        else begin
            case (state)
                IDLE: begin
                    player_led <= 8'b00000000;
                    locked <= 1'b0;
                    time_expired <= 1'b0;
                    round_active <= 1'b0;
                    buzzer_sound <= 1'b0;
                    
                    if (start_round) begin
                        state <= WAITING;
                        round_active <= 1'b1;
                        timer_counter <= 26'd0;
                        seconds_remaining <= time_limit;
                    end
                end
                
                WAITING: begin
                    round_active <= 1'b1;
                    
                    if (enable_timer && seconds_remaining > 0) begin
                        if (timer_counter >= 26'd50000000) begin
                            timer_counter <= 26'd0;
                            seconds_remaining <= seconds_remaining - 1;
                        end
                        else begin
                            timer_counter <= timer_counter + 1;
                        end
                        
                        if (seconds_remaining == 0) begin
                            state <= TIME_OUT;
                            time_expired <= 1'b1;
                        end
                    end
                    
                    if (|buzzers) begin
                        state <= LOCKED;
                        locked <= 1'b1;
                        
                        case (winner_id)
                            3'd0: player_led <= 8'b00000001;
                            3'd1: player_led <= 8'b00000010;
                            3'd2: player_led <= 8'b00000100;
                            3'd3: player_led <= 8'b00001000;
                            3'd4: player_led <= 8'b00010000;
                            3'd5: player_led <= 8'b00100000;
                            3'd6: player_led <= 8'b01000000;
                            3'd7: player_led <= 8'b10000000;
                        endcase
                        
                        buzzer_sound <= 1'b1;
                        sound_counter <= 16'd0;
                    end
                end
                
                LOCKED: begin
                    locked <= 1'b1;
                    
                    if (sound_counter < 16'd25000) begin
                        if (sound_counter[9:0] < 10'd500)
                            buzzer_sound <= 1'b1;
                        else
                            buzzer_sound <= 1'b0;
                        sound_counter <= sound_counter + 1;
                    end
                    else begin
                        buzzer_sound <= 1'b0;
                    end
                    
                    state <= SCORING;
                end
                
                SCORING: begin
                    scores[winner_id] <= scores[winner_id] + 1;
                    state <= IDLE;
                end
                
                TIME_OUT: begin
                    time_expired <= 1'b1;
                    locked <= 1'b1;
                    player_led <= 8'b11111111;
                    
                    if (sound_counter < 16'd15000) begin
                        if (sound_counter[8:0] < 9'd250)
                            buzzer_sound <= 1'b1;
                        else
                            buzzer_sound <= 1'b0;
                        sound_counter <= sound_counter + 1;
                    end
                    else begin
                        buzzer_sound <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            display_refresh <= 16'd0;
            display_digit <= 2'd0;
        end
        else begin
            if (display_refresh >= 16'd50000) begin
                display_refresh <= 16'd0;
                display_digit <= display_digit + 1;
            end
            else begin
                display_refresh <= display_refresh + 1;
            end
        end
    end
    
    always @(*) begin
        case (display_digit)
            2'd0: begin
                seg_select = 4'b0001;
                seg_display = 7'b1110011;
            end
            2'd1: begin
                seg_select = 4'b0010;
                seg_display = seg_decode(winner_id + 1);
            end
            2'd2: begin
                seg_select = 4'b0100;
                seg_display = seg_decode(scores[winner_id] / 10);
            end
            2'd3: begin
                seg_select = 4'b1000;
                seg_display = seg_decode(scores[winner_id] % 10);
            end
        endcase
    end

endmodule
