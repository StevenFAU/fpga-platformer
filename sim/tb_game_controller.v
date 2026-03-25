`timescale 1ns / 1ps

module tb_game_controller;

    reg        clk;
    reg        rst_n;
    reg        vsync;
    reg        btn_left, btn_right, btn_jump;
    wire [9:0] player_x, player_y;

    game_controller uut (
        .clk(clk),
        .rst_n(rst_n),
        .vsync(vsync),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_jump(btn_jump),
        .player_x(player_x),
        .player_y(player_y)
    );

    // 25 MHz clock → 40 ns period
    initial clk = 0;
    always #20 clk = ~clk;

    integer errors;
    integer i;

    // Task: generate one frame tick (vsync rising edge)
    // Set vsync on negedge so it's stable at the next posedge
    task do_frame;
        begin
            @(negedge clk);
            vsync = 1'b1;
            @(posedge clk);  // frame_tick fires here
            @(posedge clk);
            @(negedge clk);
            vsync = 1'b0;
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("game_controller.vcd");
        $dumpvars(0, tb_game_controller);

        errors = 0;
        rst_n = 0;
        vsync = 0;
        btn_left = 0;
        btn_right = 0;
        btn_jump = 0;

        #200;
        rst_n = 1;
        #100;

        // ── Test 1: Initial position ──
        if (player_x == 100 && player_y == 424)
            $display("PASS: Initial position (%0d, %0d)", player_x, player_y);
        else begin
            $display("FAIL: Initial position (%0d, %0d), expected (100, 424)", player_x, player_y);
            errors = errors + 1;
        end

        // ── Test 2: Move right ──
        btn_right = 1;
        do_frame;
        btn_right = 0;
        if (player_x == 103)
            $display("PASS: Moved right to x=%0d", player_x);
        else begin
            $display("FAIL: After right, x=%0d, expected 103", player_x);
            errors = errors + 1;
        end

        // ── Test 3: Move left ──
        btn_left = 1;
        do_frame;
        btn_left = 0;
        if (player_x == 100)
            $display("PASS: Moved left back to x=%0d", player_x);
        else begin
            $display("FAIL: After left, x=%0d, expected 100", player_x);
            errors = errors + 1;
        end

        // ── Test 4: Player stays on ground (no falling through) ──
        // Run several frames with no input
        for (i = 0; i < 10; i = i + 1)
            do_frame;
        if (player_y == 424)
            $display("PASS: Player stays on ground at y=%0d", player_y);
        else begin
            $display("FAIL: Player drifted to y=%0d, expected 424", player_y);
            errors = errors + 1;
        end

        // ── Test 5: Jump ──
        btn_jump = 1;
        do_frame;
        btn_jump = 0;
        // After 1 frame: vel_y should be JUMP_VEL + GRAVITY = -64 + 3 = -61
        // pos_y_full should have moved up
        if (player_y < 424)
            $display("PASS: Player jumped, y=%0d (above 424)", player_y);
        else begin
            $display("FAIL: Player didn't jump, y=%0d", player_y);
            errors = errors + 1;
        end

        // ── Test 6: Player reaches apex and falls back ──
        // Run frames until player is back on ground
        for (i = 0; i < 100; i = i + 1) begin
            do_frame;
            if (player_y == 424) begin
                $display("PASS: Player landed back on ground after %0d frames", i + 1);
                i = 999; // break
            end
        end
        if (i == 100) begin
            $display("FAIL: Player never landed, y=%0d", player_y);
            errors = errors + 1;
        end

        // ── Test 7: Can't move past left screen edge ──
        // Move far left
        btn_left = 1;
        for (i = 0; i < 200; i = i + 1)
            do_frame;
        btn_left = 0;
        if (player_x == 0)
            $display("PASS: Player clamped at left edge, x=%0d", player_x);
        else begin
            $display("FAIL: Player at x=%0d, expected 0", player_x);
            errors = errors + 1;
        end

        // ── Test 8: Can't move past right screen edge ──
        btn_right = 1;
        for (i = 0; i < 300; i = i + 1)
            do_frame;
        btn_right = 0;
        if (player_x == 624) // 640 - 16
            $display("PASS: Player clamped at right edge, x=%0d", player_x);
        else begin
            $display("FAIL: Player at x=%0d, expected 624", player_x);
            errors = errors + 1;
        end

        $display("========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);
        $display("========================================");
        $finish;
    end

endmodule
