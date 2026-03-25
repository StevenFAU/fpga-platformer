`timescale 1ns / 1ps

module game_controller (
    input  wire       clk,        // 25 MHz pixel clock
    input  wire       rst_n,
    input  wire       vsync,      // used for frame timing
    input  wire       btn_left,
    input  wire       btn_right,
    input  wire       btn_jump,
    output wire [9:0] player_x,   // pixel position for renderer
    output wire [9:0] player_y    // pixel position for renderer
);

    // ── Player dimensions ──
    localparam PLAYER_W = 16;
    localparam PLAYER_H = 24;

    // ── Movement constants ──
    // Positions use 4 fractional bits (multiply pixel values by 16)
    localparam SPEED_X      = 3;       // pixels/frame
    localparam GRAVITY      = 3;       // sub-pixels/frame² (0.1875 px/frame²)
    localparam JUMP_VEL     = -64;     // sub-pixels/frame (-4 px/frame)
    localparam TERMINAL_VEL = 80;      // sub-pixels/frame (+5 px/frame)

    // ── Screen bounds ──
    localparam SCREEN_W = 640;
    localparam SCREEN_H = 480;

    // ── Platform definitions: {x, y, width} — all 8px tall ──
    // Ground
    localparam GROUND_Y = 448;
    localparam GROUND_H = 32;
    // Floating platforms
    localparam NUM_PLATS  = 5;
    localparam PLAT_H     = 8;
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

    // ── Player start position ──
    localparam START_X = 100;
    localparam START_Y_FULL = (GROUND_Y - PLAYER_H) <<< 4; // 424 * 16 = 6784

    // ── State registers ──
    reg [9:0]        pos_x;
    reg signed [15:0] pos_y_full;   // [15:4]=pixel, [3:0]=fraction
    reg signed [9:0]  vel_y;        // sub-pixel velocity
    reg               on_ground;

    // ── Frame tick: detect vsync rising edge ──
    reg vsync_prev;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            vsync_prev <= 1'b0;
        else
            vsync_prev <= vsync;
    end
    wire frame_tick = vsync & ~vsync_prev;

    // ── Output pixel positions ──
    assign player_x = pos_x;
    assign player_y = pos_y_full[13:4];

    // ── Collision helper: check horizontal overlap with a platform ──
    // Player horizontal range: [pos_x, pos_x + PLAYER_W)
    // Platform horizontal range: [plat_x, plat_x + plat_w)
    // Overlap exists when: player_right > plat_left AND player_left < plat_right

    // ── Per-frame game update ──
    reg signed [15:0] new_y_full;
    reg [9:0] new_x;
    reg signed [9:0] new_vel_y;
    wire [9:0] new_y_pixel;
    wire [9:0] new_bottom;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pos_x      <= START_X;
            pos_y_full <= START_Y_FULL;
            vel_y      <= 10'sd0;
            on_ground  <= 1'b1;
        end else if (frame_tick) begin

            // ── 1. Horizontal movement ──
            new_x = pos_x;
            if (btn_left && pos_x > SPEED_X)
                new_x = pos_x - SPEED_X;
            else if (btn_left)
                new_x = 0;

            if (btn_right && pos_x < SCREEN_W - PLAYER_W - SPEED_X)
                new_x = pos_x + SPEED_X;
            else if (btn_right)
                new_x = SCREEN_W - PLAYER_W;

            pos_x <= new_x;

            // ── 2. Jump initiation ──
            new_vel_y = vel_y;
            if (btn_jump && on_ground) begin
                new_vel_y = JUMP_VEL;
                on_ground <= 1'b0;
            end

            // ── 3. Apply gravity ──
            if (!on_ground || new_vel_y < 0) begin
                new_vel_y = new_vel_y + GRAVITY;
                if (new_vel_y > TERMINAL_VEL)
                    new_vel_y = TERMINAL_VEL;
            end

            // ── 4. Apply vertical velocity ──
            new_y_full = pos_y_full + new_vel_y;

            // ── 5. Collision detection (only when falling) ──
            // Extract pixel position of bottom edge after move
            // new_bottom = new_y_pixel + PLAYER_H
            if (new_vel_y >= 0) begin
                // Check ground
                if (new_y_full[13:4] + PLAYER_H >= GROUND_Y) begin
                    new_y_full = (GROUND_Y - PLAYER_H) <<< 4;
                    new_vel_y = 0;
                    on_ground <= 1'b1;
                end
                // Check platform 0
                else if (pos_y_full[13:4] + PLAYER_H <= P0_Y &&
                         new_y_full[13:4] + PLAYER_H >= P0_Y &&
                         new_x + PLAYER_W > P0_X &&
                         new_x < P0_X + P0_W) begin
                    new_y_full = (P0_Y - PLAYER_H) <<< 4;
                    new_vel_y = 0;
                    on_ground <= 1'b1;
                end
                // Check platform 1
                else if (pos_y_full[13:4] + PLAYER_H <= P1_Y &&
                         new_y_full[13:4] + PLAYER_H >= P1_Y &&
                         new_x + PLAYER_W > P1_X &&
                         new_x < P1_X + P1_W) begin
                    new_y_full = (P1_Y - PLAYER_H) <<< 4;
                    new_vel_y = 0;
                    on_ground <= 1'b1;
                end
                // Check platform 2
                else if (pos_y_full[13:4] + PLAYER_H <= P2_Y &&
                         new_y_full[13:4] + PLAYER_H >= P2_Y &&
                         new_x + PLAYER_W > P2_X &&
                         new_x < P2_X + P2_W) begin
                    new_y_full = (P2_Y - PLAYER_H) <<< 4;
                    new_vel_y = 0;
                    on_ground <= 1'b1;
                end
                // Check platform 3
                else if (pos_y_full[13:4] + PLAYER_H <= P3_Y &&
                         new_y_full[13:4] + PLAYER_H >= P3_Y &&
                         new_x + PLAYER_W > P3_X &&
                         new_x < P3_X + P3_W) begin
                    new_y_full = (P3_Y - PLAYER_H) <<< 4;
                    new_vel_y = 0;
                    on_ground <= 1'b1;
                end
                // Check platform 4
                else if (pos_y_full[13:4] + PLAYER_H <= P4_Y &&
                         new_y_full[13:4] + PLAYER_H >= P4_Y &&
                         new_x + PLAYER_W > P4_X &&
                         new_x < P4_X + P4_W) begin
                    new_y_full = (P4_Y - PLAYER_H) <<< 4;
                    new_vel_y = 0;
                    on_ground <= 1'b1;
                end
                else begin
                    on_ground <= 1'b0;
                end
            end else begin
                on_ground <= 1'b0;
            end

            // ── 6. Clamp to screen top ──
            if (new_y_full < 0)
                new_y_full = 0;

            // ── Commit new state ──
            pos_y_full <= new_y_full;
            vel_y      <= new_vel_y;
        end
    end

endmodule
