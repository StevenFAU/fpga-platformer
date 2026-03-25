`timescale 1ns / 1ps

module btn_debounce (
    input  wire clk,      // 25 MHz
    input  wire rst_n,
    input  wire btn_in,   // raw button (active-high)
    output reg  btn_out   // debounced output
);

    localparam DEBOUNCE_LIMIT = 500000; // ~20ms at 25 MHz

    reg [19:0] counter;
    reg        btn_sync_0, btn_sync_1;

    // Two-stage synchronizer to avoid metastability
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_sync_0 <= 1'b0;
            btn_sync_1 <= 1'b0;
        end else begin
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;
        end
    end

    // Debounce: accept new value only after it's been stable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 20'd0;
            btn_out <= 1'b0;
        end else if (btn_sync_1 != btn_out) begin
            if (counter == DEBOUNCE_LIMIT) begin
                btn_out <= btn_sync_1;
                counter <= 20'd0;
            end else begin
                counter <= counter + 1'b1;
            end
        end else begin
            counter <= 20'd0;
        end
    end

endmodule
