`timescale 1ns / 1ps

module tb_renderer;

    reg  [9:0] pixel_x, pixel_y;
    reg  [9:0] player_x, player_y;
    reg        video_on;
    wire [3:0] vga_r, vga_g, vga_b;

    renderer uut (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .player_x(player_x),
        .player_y(player_y),
        .video_on(video_on),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

    integer errors;

    // Helper: check expected RGB
    task check_color;
        input [3:0] exp_r, exp_g, exp_b;
        input [8*32-1:0] label;  // string label
        begin
            #10;
            if (vga_r == exp_r && vga_g == exp_g && vga_b == exp_b)
                $display("PASS: %0s — RGB=(%h,%h,%h)", label, vga_r, vga_g, vga_b);
            else begin
                $display("FAIL: %0s — RGB=(%h,%h,%h), expected (%h,%h,%h)",
                         label, vga_r, vga_g, vga_b, exp_r, exp_g, exp_b);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("renderer.vcd");
        $dumpvars(0, tb_renderer);

        errors = 0;
        video_on = 1;
        player_x = 100;
        player_y = 424;

        // ── Test 1: Background pixel (empty space) ──
        pixel_x = 10; pixel_y = 10;
        check_color(4'h0, 4'h0, 4'h3, "Background");

        // ── Test 2: Player pixel ──
        pixel_x = 108; pixel_y = 430;
        check_color(4'hF, 4'h2, 4'h0, "Player");

        // ── Test 3: Ground pixel ──
        pixel_x = 320; pixel_y = 460;
        check_color(4'h1, 4'h8, 4'h1, "Ground");

        // ── Test 4: Platform 0 pixel ──
        pixel_x = 100; pixel_y = 370;
        check_color(4'h8, 4'h5, 4'h1, "Platform 0");

        // ── Test 5: Platform 1 pixel ──
        pixel_x = 350; pixel_y = 306;
        check_color(4'h8, 4'h5, 4'h1, "Platform 1");

        // ── Test 6: Platform 4 (highest) ──
        pixel_x = 400; pixel_y = 178;
        check_color(4'h8, 4'h5, 4'h1, "Platform 4");

        // ── Test 7: Just above a platform should be background ──
        pixel_x = 100; pixel_y = 367;
        check_color(4'h0, 4'h0, 4'h3, "Above Platform 0");

        // ── Test 8: Video off should be black ──
        video_on = 0;
        pixel_x = 108; pixel_y = 430;
        check_color(4'h0, 4'h0, 4'h0, "Video off");

        // ── Test 9: Player drawn on top of ground ──
        video_on = 1;
        player_x = 320;
        player_y = 440;  // overlapping ground
        pixel_x = 325;
        pixel_y = 450;   // inside both player and ground
        check_color(4'hF, 4'h2, 4'h0, "Player over ground");

        $display("========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);
        $display("========================================");
        $finish;
    end

endmodule
