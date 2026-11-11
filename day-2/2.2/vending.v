`timescale 1ns/1ps
// Vending controller for an item costing Rs.15.
// Inputs coin5 and coin10 are one-cycle coin pulses and must not be high together.
// dispense, change and refund are one-cycle registered outputs.
// change/refund are amounts in rupees, represented as 5-bit unsigned values.
module vending (
    input  wire       clk,
    input  wire       reset,
    input  wire       coin5,
    input  wire       coin10,
    input  wire       cancel,
    output reg        dispense,
    output reg  [4:0] change,
    output reg  [4:0] refund
);
    localparam IDLE = 2'd0,
               CREDIT5 = 2'd1,
               CREDIT10 = 2'd2;

    reg [1:0] state, next_state;
    reg dispense_next;
    reg [4:0] change_next;
    reg [4:0] refund_next;

    // State register and registered one-cycle transaction outputs.
    always @(posedge clk) begin
        if (reset) begin
            state    <= IDLE;
            dispense <= 1'b0;
            change   <= 5'd0;
            refund   <= 5'd0;
        end else begin
            state    <= next_state;
            dispense <= dispense_next;
            change   <= change_next;
            refund   <= refund_next;
        end
    end

    // Next-state and output logic.
    always @* begin
        next_state    = state;
        dispense_next = 1'b0;
        change_next   = 5'd0;
        refund_next   = 5'd0;

        // Cancel has priority over coin acceptance. It refunds current credit.
        if (cancel) begin
            case (state)
                CREDIT5:  refund_next = 5'd5;
                CREDIT10: refund_next = 5'd10;
                default:  refund_next = 5'd0;
            endcase
            next_state = IDLE;
        end else begin
            // Coin inputs are mutually exclusive by interface contract.
            case (state)
                IDLE: begin
                    if (coin5)
                        next_state = CREDIT5;
                    else if (coin10)
                        next_state = CREDIT10;
                end

                CREDIT5: begin
                    if (coin5)
                        next_state = CREDIT10;
                    else if (coin10) begin
                        dispense_next = 1'b1;
                        next_state = IDLE;
                    end
                end

                CREDIT10: begin
                    if (coin5) begin
                        dispense_next = 1'b1;
                        next_state = IDLE;
                    end else if (coin10) begin
                        dispense_next = 1'b1;
                        change_next = 5'd5;
                        next_state = IDLE;
                    end
                end

                default: next_state = IDLE;
            endcase
        end
    end
endmodule
