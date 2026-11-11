`timescale 1ns/1ps
// Overlapping 1011 sequence detector - Mealy FSM.
// Output is asserted when the final 1 completes the sequence.
module seq_mealy (
    input  wire clk,
    input  wire reset,
    input  wire serial_in,
    output reg  detected
);
    localparam S0   = 2'd0, // no useful prefix
               S1   = 2'd1, // seen 1
               S10  = 2'd2, // seen 10
               S101 = 2'd3; // seen 101

    reg [1:0] state, next_state;

    always @(posedge clk) begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

    always @* begin
        next_state = S0;
        detected = 1'b0;
        case (state)
            S0: begin
                next_state = serial_in ? S1 : S0;
            end
            S1: begin
                next_state = serial_in ? S1 : S10;
            end
            S10: begin
                next_state = serial_in ? S101 : S0;
            end
            S101: begin
                if (serial_in) begin
                    detected = 1'b1;
                    next_state = S1; // overlap: final 1 is next prefix
                end else begin
                    next_state = S10;
                end
            end
            default: begin
                next_state = S0;
                detected = 1'b0;
            end
        endcase
    end
endmodule
