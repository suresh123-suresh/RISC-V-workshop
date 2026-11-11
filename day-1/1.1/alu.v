`timescale 1ns/1ps

// Activity 1.1: Parameterized ALU
// Operations:
// 000 ADD, 001 SUB, 010 AND, 011 OR,
// 100 XOR, 101 signed SLT, 110 logical shift left, 111 logical shift right.
module alu #(
    parameter DATA_WIDTH = 32
)(
    input  wire [DATA_WIDTH-1:0] a,
    input  wire [DATA_WIDTH-1:0] b,
    input  wire [2:0]            alu_op,
    output reg  [DATA_WIDTH-1:0] result,
    output reg                   zero,
    output reg                   negative,
    output reg                   carry,
    output reg                   overflow
);

    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_AND = 3'b010;
    localparam OP_OR  = 3'b011;
    localparam OP_XOR = 3'b100;
    localparam OP_SLT = 3'b101;
    localparam OP_SLL = 3'b110;
    localparam OP_SRL = 3'b111;

    // The low log2(DATA_WIDTH) bits of b select the shift amount.
    localparam SHAMT_WIDTH = (DATA_WIDTH > 1) ? $clog2(DATA_WIDTH) : 1;

    reg [DATA_WIDTH:0] extended_result;

    always @(*) begin
        result   = {DATA_WIDTH{1'b0}};
        carry    = 1'b0;
        overflow = 1'b0;
        extended_result = {(DATA_WIDTH+1){1'b0}};

        case (alu_op)
            OP_ADD: begin
                extended_result = {1'b0, a} + {1'b0, b};
                result = extended_result[DATA_WIDTH-1:0];
                carry = extended_result[DATA_WIDTH];
                overflow = (~(a[DATA_WIDTH-1] ^ b[DATA_WIDTH-1])) &
                           (result[DATA_WIDTH-1] ^ a[DATA_WIDTH-1]);
            end

            OP_SUB: begin
                extended_result = {1'b0, a} - {1'b0, b};
                result = extended_result[DATA_WIDTH-1:0];
                // For subtraction, carry=1 means no unsigned borrow.
                carry = (a >= b);
                overflow = (a[DATA_WIDTH-1] ^ b[DATA_WIDTH-1]) &
                           (result[DATA_WIDTH-1] ^ a[DATA_WIDTH-1]);
            end

            OP_AND: result = a & b;
            OP_OR : result = a | b;
            OP_XOR: result = a ^ b;

            OP_SLT: begin
                result = ($signed(a) < $signed(b)) ?
                         {{(DATA_WIDTH-1){1'b0}}, 1'b1} :
                         {DATA_WIDTH{1'b0}};
            end

            OP_SLL: begin
                result = a << b[SHAMT_WIDTH-1:0];
                if (b[SHAMT_WIDTH-1:0] != 0)
                    carry = a[DATA_WIDTH - b[SHAMT_WIDTH-1:0]];
            end

            OP_SRL: begin
                result = a >> b[SHAMT_WIDTH-1:0];
                if (b[SHAMT_WIDTH-1:0] != 0)
                    carry = a[b[SHAMT_WIDTH-1:0] - 1'b1];
            end

            default: begin
                result   = {DATA_WIDTH{1'b0}};
                carry    = 1'b0;
                overflow = 1'b0;
            end
        endcase

        zero = (result == {DATA_WIDTH{1'b0}});
        negative = result[DATA_WIDTH-1];
    end

endmodule
