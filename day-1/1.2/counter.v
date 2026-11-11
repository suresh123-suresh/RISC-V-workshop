`timescale 1ns/1ps

// Activity 1.2: 8-bit Up/Down Counter
// Synchronous reset, enable, direction control and parallel load.
// Priority: reset > load > enable > hold.
module counter (
    input  wire       clk,
    input  wire       reset,
    input  wire       enable,
    input  wire       up_down,   // 1 = count up, 0 = count down
    input  wire       load,
    input  wire [7:0] load_data,
    output reg  [7:0] count
);

    always @(posedge clk) begin
        if (reset)
            count <= 8'd0;
        else if (load)
            count <= load_data;
        else if (enable) begin
            if (up_down)
                count <= count + 1'b1;
            else
                count <= count - 1'b1;
        end
        // Otherwise hold the previous count.
    end

endmodule
