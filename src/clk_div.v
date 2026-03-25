`timescale 1ns / 1ps

module clk_div (
    input  wire clk_100mhz,
    input  wire rst_n,
    output reg  clk_25mhz
);

    reg [1:0] counter;

    always @(posedge clk_100mhz or negedge rst_n) begin
        if (!rst_n) begin
            counter   <= 2'b0;
            clk_25mhz <= 1'b0;
        end else begin
            if (counter == 2'd1) begin
                counter   <= 2'b0;
                clk_25mhz <= ~clk_25mhz;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

endmodule
