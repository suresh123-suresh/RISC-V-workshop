`timescale 1ns/1ps

// Activity 1.3: 32-bit combinational barrel shifter.
// mode = 00: logical left
// mode = 01: logical right
// mode = 10: arithmetic right (signed)
// mode = 11: output zero
module shifter (
    input  wire [31:0] data_in,
    input  wire [4:0]  shamt,
    input  wire [1:0]  mode,
    output reg  [31:0] data_out
);

    always @(*) begin
        case (mode)
            2'b00: data_out = data_in << shamt;
            2'b01: data_out = data_in >> shamt;
            2'b10: data_out = $signed(data_in) >>> shamt;
            default: data_out = 32'b0;
        endcase
    end

endmodule
