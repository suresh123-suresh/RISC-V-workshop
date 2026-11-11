`timescale 1ns/1ps
// Overlapping 1011 sequence detector - Moore FSM.
// Output is asserted while the FSM is in DETECT state.
module seq_moore (
    input  wire clk,
    input  wire reset,
    input  wire serial_in,
    output reg  detected
);
    localparam S0    = 3'd0, // no useful prefix
               S1    = 3'd1, // seen 1
               S10   = 3'd2, // seen 10
               S101  = 3'd3, // seen 101
               S1011 = 3'd4; // detected 1011

    reg [2:0] state, next_state;

    always @(posedge clk) begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

    always @* begin
        next_state = S0;
        case (state)
            S0:    next_state = serial_in ? S1 : S0;
            S1:    next_state = serial_in ? S1 : S10;
            S10:   next_state = serial_in ? S101 : S0;
            S101:  next_state = serial_in ? S1011 : S10;
            // Keep overlap: 1011 ends in 1, which is a valid prefix.
            S1011: next_state = serial_in ? S1 : S10;
            default: next_state = S0;
        endcase
    end

    always @* begin
        detected = (state == S1011);
    end
endmodule
