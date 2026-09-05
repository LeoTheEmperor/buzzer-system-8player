module buzzer_system_tb;
    reg clk;
    reg rst;
    reg [7:0] buzzers;
    reg start_round;
    reg enable_timer;
    reg [3:0] time_limit;
    
    wire [7:0] player_led;
    wire locked;
    wire [2:0] winner_id;
    wire [7:0] scores [0:7];
    wire buzzer_sound;
    wire [6:0] seg_display;
    wire [3:0] seg_select;
    wire time_expired;
    wire round_active;
    
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    buzzer_system uut (
        .clk(clk),
        .rst(rst),
        .buzzers(buzzers),
        .start_round(start_round),
        .enable_timer(enable_timer),
        .time_limit(time_limit),
        .player_led(player_led),
        .locked(locked),
        .winner_id(winner_id),
        .scores(scores),
        .buzzer_sound(buzzer_sound),
        .seg_display(seg_display),
        .seg_select(seg_select),
        .time_expired(time_expired),
        .round_active(round_active)
    );
    
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    task start_new_round;
        input enable_timer_flag;
        input [3:0] time_limit_val;
        begin
            enable_timer = enable_timer_flag;
            time_limit = time_limit_val;
            start_round = 1;
            #40;
            start_round = 0;
            #100;
        end
    endtask
    
    task press_buzzer;
        input [7:0] buzzer_mask;
        input integer hold_time;
        begin
            buzzers = buzzer_mask;
            #hold_time;
            buzzers = 8'b00000000;
        end
    endtask
    
    task check_result;
        input [2:0] expected_winner;
        input [7:0] expected_led;
        input expected_locked;
        input [127:0] test_name;
        begin
            test_count = test_count + 1;
            if (winner_id == expected_winner && player_led == expected_led && locked == expected_locked) begin
                $display("[PASS] Test %0d: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s", test_count, test_name);
                $display("       Expected: Winner=P%0d, LED=%b, Locked=%b", 
                         expected_winner+1, expected_led, expected_locked);
                $display("       Got:      Winner=P%0d, LED=%b, Locked=%b", 
                         winner_id+1, player_led, locked);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    initial begin
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        $display("\n");
        $display("================================================================================");
        $display("           ADVANCED BUZZER SYSTEM - COMPREHENSIVE TESTBENCH");
        $display("================================================================================");
        $display("\n");
        
        rst = 1;
        buzzers = 8'b00000000;
        start_round = 0;
        enable_timer = 0;
        time_limit = 4'd5;
        #100;
        
        rst = 0;
        #100;
        
        $display("\n--- TEST SUITE 1: Basic Functionality ---\n");
        
        $display("Test 1.1: Single Player Buzzer (Player 1)");
        start_new_round(0, 4'd5);
        press_buzzer(8'b00000001, 500);
        #1000;
        check_result(3'd0, 8'b00000001, 1'b1, "Player 1 wins");
        #1000;
        
        $display("\nTest 1.2: Single Player Buzzer (Player 8)");
        start_new_round(0, 4'd5);
        press_buzzer(8'b10000000, 500);
        #1000;
        check_result(3'd7, 8'b10000000, 1'b1, "Player 8 wins");
        #1000;
        
        $display("\nTest 1.3: Lockout Mechanism Test");
        start_new_round(0, 4'd5);
        press_buzzer(8'b00000100, 300);
        #200;
        press_buzzer(8'b00000001, 300);
        #1000;
        check_result(3'd2, 8'b00000100, 1'b1, "Player 3 locked, Player 1 ignored");
        #1000;
        
        $display("\n--- TEST SUITE 2: Priority Encoder Tests ---\n");
        
        $display("Test 2.1: Simultaneous Press - Players 1 and 5");
        start_new_round(0, 4'd5);
        press_buzzer(8'b00010001, 500);
        #1000;
        check_result(3'd0, 8'b00000001, 1'b1, "Player 1 has priority");
        #1000;
        
        $display("\nTest 2.2: Simultaneous Press - Players 2, 4, and 7");
        start_new_round(0, 4'd5);
        press_buzzer(8'b01001010, 500);
        #1000;
        check_result(3'd1, 8'b00000010, 1'b1, "Player 2 has highest priority");
        #1000;
        
        $display("\nTest 2.3: All Players Press Simultaneously");
        start_new_round(0, 4'd5);
        press_buzzer(8'b11111111, 500);
        #1000;
        check_result(3'd0, 8'b00000001, 1'b1, "Player 1 has highest priority");
        #1000;
        
        $display("\n--- TEST SUITE 3: Score Tracking Tests ---\n");
        
        $display("Test 3.1: Player 3 Wins Multiple Rounds");
        start_new_round(0, 4'd5);
        press_buzzer(8'b00000100, 500);
        #1500;
        
        start_new_round(0, 4'd5);
        press_buzzer(8'b00000100, 500);
        #1500;
        
        if (scores[2] == 8'd2) begin
            $display("[PASS] Player 3 score = 2");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Player 3 score = %0d (expected 2)", scores[2]);
            fail_count = fail_count + 1;
        end
        test_count = test_count + 1;
        
        $display("\nTest 3.2: Multiple Players Accumulating Scores");
        start_new_round(0, 4'd5);
        press_buzzer(8'b00000001, 500);
        #1500;
        
        start_new_round(0, 4'd5);
        press_buzzer(8'b01000000, 500);
        #1500;
        
        start_new_round(0, 4'd5);
        press_buzzer(8'b00000001, 500);
        #1500;
        
        if (scores[0] == 8'd2 && scores[6] == 8'd1) begin
            $display("[PASS] Player 1 score = 2, Player 7 score = 1");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Player 1 score = %0d (expected 2), Player 7 score = %0d (expected 1)", 
                     scores[0], scores[6]);
            fail_count = fail_count + 1;
        end
        test_count = test_count + 1;
        
        $display("\n--- TEST SUITE 4: Reset Functionality Tests ---\n");
        
        $display("Test 4.1: Reset During Active Round");
        start_new_round(0, 4'd5);
        press_buzzer(8'b00001000, 200);
        #500;
        rst = 1;
        #100;
        rst = 0;
        #100;
        check_result(3'd0, 8'b00000000, 1'b0, "System reset to idle state");
        
        $display("\nTest 4.2: Verify Scores Reset to Zero");
        if (scores[0] == 0 && scores[1] == 0 && scores[2] == 0 && scores[3] == 0 &&
            scores[4] == 0 && scores[5] == 0 && scores[6] == 0 && scores[7] == 0) begin
            $display("[PASS] All scores reset to 0");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Scores not properly reset");
            fail_count = fail_count + 1;
        end
        test_count = test_count + 1;
        #1000;
        
        $display("\n--- TEST SUITE 5: Edge Cases ---\n");
        
        $display("Test 5.1: No Buzzer Press (Timeout Expected)");
        start_new_round(0, 4'd5);
        #2000;
        check_result(3'd0, 8'b00000000, 1'b0, "No winner, system stays in waiting");
        #1000;
        
        $display("\nTest 5.2: Rapid Successive Rounds");
        start_new_round(0, 4'd5);
        press_buzzer(8'b00000010, 200);
        #500;
        
        start_new_round(0, 4'd5);
        press_buzzer(8'b00100000, 200);
        #500;
        
        start_new_round(0, 4'd5);
        press_buzzer(8'b00000001, 200);
        #500;
        
        if (scores[1] >= 1 && scores[5] >= 1 && scores[0] >= 1) begin
            $display("[PASS] Rapid rounds handled correctly");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Rapid rounds not handled properly");
            fail_count = fail_count + 1;
        end
        test_count = test_count + 1;
        
        $display("\nTest 5.3: Buzzer Press Before Round Start");
        buzzers = 8'b00010000;
        #500;
        start_new_round(0, 4'd5);
        buzzers = 8'b00000000;
        #500;
        check_result(3'd0, 8'b00000000, 1'b0, "Premature press ignored");
        #1000;
        
        $display("\n--- TEST SUITE 6: Display and Audio (Visual Verification) ---\n");
        
        $display("Test 6.1: Buzzer Sound Generation");
        start_new_round(0, 4'd5);
        press_buzzer(8'b00000001, 300);
        #100;
        if (buzzer_sound == 1'b1) begin
            $display("[PASS] Buzzer sound activated");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Buzzer sound not activated");
            fail_count = fail_count + 1;
        end
        test_count = test_count + 1;
        #2000;
        
        $display("\nTest 6.2: 7-Segment Display Multiplexing");
        start_new_round(0, 4'd5);
        press_buzzer(8'b00001000, 300);
        #1000;
        $display("       Display is multiplexing (check seg_select and seg_display signals)");
        $display("       seg_select should cycle through 4'b0001, 4'b0010, 4'b0100, 4'b1000");
        #2000;
        
        $display("\n");
        $display("================================================================================");
        $display("                          FINAL SCORE BOARD");
        $display("================================================================================");
        $display("Player 1: %0d points", scores[0]);
        $display("Player 2: %0d points", scores[1]);
        $display("Player 3: %0d points", scores[2]);
        $display("Player 4: %0d points", scores[3]);
        $display("Player 5: %0d points", scores[4]);
        $display("Player 6: %0d points", scores[5]);
        $display("Player 7: %0d points", scores[6]);
        $display("Player 8: %0d points", scores[7]);
        $display("================================================================================");
        
        $display("\n");
        $display("================================================================================");
        $display("                          TEST SUMMARY");
        $display("================================================================================");
        $display("Total Tests:  %0d", test_count);
        $display("Tests Passed: %0d", pass_count);
        $display("Tests Failed: %0d", fail_count);
        $display("Pass Rate:    %0d%%", (pass_count * 100) / test_count);
        $display("================================================================================");
        
        if (fail_count == 0) begin
            $display("\n*** ALL TESTS PASSED! ***\n");
        end else begin
            $display("\n*** SOME TESTS FAILED - CHECK LOGS ***\n");
        end
        
        #1000;
        $finish;
    end
    endmodule
