`timescale 1ns / 1ps

module vga_timing (
    input  wire       clk,      // 25 MHz pixel clock
    input  wire       rst_n,
    output wire       hsync,
    output wire       vsync,
    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y,
    output wire       video_on
);

    // 640x480 @ 60 Hz timing constants
    localparam H_VISIBLE    = 640;
    localparam H_FRONT      = 16;
    localparam H_SYNC       = 96;
    localparam H_BACK       = 48;
    localparam H_TOTAL      = H_VISIBLE + H_FRONT + H_SYNC + H_BACK; // 800

    localparam V_VISIBLE    = 480;
    localparam V_FRONT      = 10;
    localparam V_SYNC       = 2;
    localparam V_BACK       = 33;
    localparam V_TOTAL      = V_VISIBLE + V_FRONT + V_SYNC + V_BACK; // 525

    reg [9:0] h_count;
    reg [9:0] v_count;

    // Horizontal counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            h_count <= 10'd0;
        else if (h_count == H_TOTAL - 1)
            h_count <= 10'd0;
        else
            h_count <= h_count + 1'b1;
    end

    // Vertical counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            v_count <= 10'd0;
        else if (h_count == H_TOTAL - 1) begin
            if (v_count == V_TOTAL - 1)
                v_count <= 10'd0;
            else
                v_count <= v_count + 1'b1;
        end
    end

    // Sync signals (active low)
    assign hsync = ~((h_count >= H_VISIBLE + H_FRONT) &&
                     (h_count <  H_VISIBLE + H_FRONT + H_SYNC));
    assign vsync = ~((v_count >= V_VISIBLE + V_FRONT) &&
                     (v_count <  V_VISIBLE + V_FRONT + V_SYNC));

    // Pixel coordinates and video enable
    assign pixel_x  = h_count;
    assign pixel_y  = v_count;
    assign video_on = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

endmodule
