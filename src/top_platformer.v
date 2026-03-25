`timescale 1ns / 1ps

module top_platformer (
    input  wire       clk_100mhz,
    input  wire       btn_center,   // reset (active-high)
    input  wire       btn_up,       // jump
    input  wire       btn_left,     // move left
    input  wire       btn_right,    // move right
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire       vga_hsync,
    output wire       vga_vsync
);

    // Active-low reset from active-high button
    wire rst_n = ~btn_center;

    // ── Clock divider: 100 MHz → 25 MHz ──
    wire clk_25mhz;
    clk_div u_clk_div (
        .clk_100mhz(clk_100mhz),
        .rst_n(rst_n),
        .clk_25mhz(clk_25mhz)
    );

    // ── VGA timing generator ──
    wire [9:0] pixel_x, pixel_y;
    wire       video_on;
    wire       vsync_internal;
    vga_timing u_vga_timing (
        .clk(clk_25mhz),
        .rst_n(rst_n),
        .hsync(vga_hsync),
        .vsync(vsync_internal),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_on(video_on)
    );
    assign vga_vsync = vsync_internal;

    // ── Button debouncers ──
    wire btn_left_clean, btn_right_clean, btn_jump_clean;

    btn_debounce u_deb_left (
        .clk(clk_25mhz),
        .rst_n(rst_n),
        .btn_in(btn_left),
        .btn_out(btn_left_clean)
    );

    btn_debounce u_deb_right (
        .clk(clk_25mhz),
        .rst_n(rst_n),
        .btn_in(btn_right),
        .btn_out(btn_right_clean)
    );

    btn_debounce u_deb_jump (
        .clk(clk_25mhz),
        .rst_n(rst_n),
        .btn_in(btn_up),
        .btn_out(btn_jump_clean)
    );

    // ── Game controller ──
    wire [9:0] player_x, player_y;

    game_controller u_game (
        .clk(clk_25mhz),
        .rst_n(rst_n),
        .vsync(vsync_internal),
        .btn_left(btn_left_clean),
        .btn_right(btn_right_clean),
        .btn_jump(btn_jump_clean),
        .player_x(player_x),
        .player_y(player_y)
    );

    // ── Renderer ──
    renderer u_renderer (
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .player_x(player_x),
        .player_y(player_y),
        .video_on(video_on),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

endmodule
