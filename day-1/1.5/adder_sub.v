`timescale 1ns/1ps
module adder_sub(
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       mode,       // 0: A+B, 1: A-B
    output wire [7:0] result,
    output wire       carry_out,
    output wire       overflow
);
    wire [7:0] bx;
    wire [8:0] carry;
    genvar i;

    assign bx = b ^ {8{mode}};
    assign carry[0] = mode;

    generate
        for (i = 0; i < 8; i = i + 1) begin : GEN_FA
            full_adder fa (
                .a(a[i]),
                .b(bx[i]),
                .cin(carry[i]),
                .sum(result[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate

    assign carry_out = carry[8];
    // For addition: carry into MSB XOR carry out of MSB.
    // The same expression works for subtraction using two's complement.
    assign overflow = carry[7] ^ carry[8];
endmodule
