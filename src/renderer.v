`timescale 1ns / 1ps

module renderer (
    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    input  wire       video_on,
    output reg  [3:0] vga_r,
    output reg  [3:0] vga_g,
    output reg  [3:0] vga_b
);

    // ── Player dimensions ──
    localparam PLAYER_W = 16;
    localparam PLAYER_H = 24;

    // ── Platform definitions (must match game_controller.v) ──
    localparam PLAT_H = 8;
    // Ground
    localparam GROUND_Y = 448;
    localparam GROUND_H = 32;
    // Plat 0
    localparam P0_X = 80;   localparam P0_Y = 368; localparam P0_W = 120;
    // Plat 1
    localparam P1_X = 280;  localparam P1_Y = 304; localparam P1_W = 140;
    // Plat 2
    localparam P2_X = 440;  localparam P2_Y = 368; localparam P2_W = 120;
    // Plat 3
    localparam P3_X = 180;  localparam P3_Y = 240; localparam P3_W = 120;
    // Plat 4
    localparam P4_X = 380;  localparam P4_Y = 176; localparam P4_W = 100;

    // ── Colors (4-bit per channel) ──
    localparam [11:0] COLOR_BG       = 12'h003; // dark blue
    localparam [11:0] COLOR_PLAYER   = 12'hF20; // red
    localparam [11:0] COLOR_GROUND   = 12'h181; // green
    localparam [11:0] COLOR_PLATFORM = 12'h851; // brown

    // ── Hit detection ──
    wire in_player = (pixel_x >= player_x) && (pixel_x < player_x + PLAYER_W) &&
                     (pixel_y >= player_y) && (pixel_y < player_y + PLAYER_H);

    wire in_ground = (pixel_y >= GROUND_Y) && (pixel_y < GROUND_Y + GROUND_H);

    wire in_plat0 = (pixel_x >= P0_X) && (pixel_x < P0_X + P0_W) &&
                    (pixel_y >= P0_Y) && (pixel_y < P0_Y + PLAT_H);
    wire in_plat1 = (pixel_x >= P1_X) && (pixel_x < P1_X + P1_W) &&
                    (pixel_y >= P1_Y) && (pixel_y < P1_Y + PLAT_H);
    wire in_plat2 = (pixel_x >= P2_X) && (pixel_x < P2_X + P2_W) &&
                    (pixel_y >= P2_Y) && (pixel_y < P2_Y + PLAT_H);
    wire in_plat3 = (pixel_x >= P3_X) && (pixel_x < P3_X + P3_W) &&
                    (pixel_y >= P3_Y) && (pixel_y < P3_Y + PLAT_H);
    wire in_plat4 = (pixel_x >= P4_X) && (pixel_x < P4_X + P4_W) &&
                    (pixel_y >= P4_Y) && (pixel_y < P4_Y + PLAT_H);

    wire in_platform = in_plat0 | in_plat1 | in_plat2 | in_plat3 | in_plat4;

    // ── Color selection (priority: player > platform > ground > background) ──
    reg [11:0] rgb;

    always @(*) begin
        if (!video_on)
            rgb = 12'h000;
        else if (in_player)
            rgb = COLOR_PLAYER;
        else if (in_platform)
            rgb = COLOR_PLATFORM;
        else if (in_ground)
            rgb = COLOR_GROUND;
        else
            rgb = COLOR_BG;
    end

    always @(*) begin
        vga_r = rgb[11:8];
        vga_g = rgb[7:4];
        vga_b = rgb[3:0];
    end

endmodule
