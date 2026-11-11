`timescale 1ns/1ps

module alu_tb;

    localparam DATA_WIDTH = 32;

    reg  [DATA_WIDTH-1:0] a;
    reg  [DATA_WIDTH-1:0] b;
    reg  [2:0]            alu_op;
    wire [DATA_WIDTH-1:0] result;
    wire                  zero;
    wire                  negative;
    wire                  carry;
    wire                  overflow;

    integer pass_count;
    integer fail_count;

    alu #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result),
        .zero(zero),
        .negative(negative),
        .carry(carry),
        .overflow(overflow)
    );

    // Checks the result and all four flags.
    task check;
        input [DATA_WIDTH-1:0] test_a;
        input [DATA_WIDTH-1:0] test_b;
        input [2:0]            test_op;
        input [DATA_WIDTH-1:0] expected_result;
        input                  expected_carry;
        input                  expected_overflow;
        input [8*40-1:0]       test_name;
        reg                    expected_zero;
        reg                    expected_negative;
        begin
            a = test_a;
            b = test_b;
            alu_op = test_op;
            #2;

            expected_zero = (expected_result == 0);
            expected_negative = expected_result[DATA_WIDTH-1];

            if ((result !== expected_result) ||
                (zero !== expected_zero) ||
                (negative !== expected_negative) ||
                (carry !== expected_carry) ||
                (overflow !== expected_overflow)) begin
                $display("FAIL: %0s", test_name);
                $display("  op=%b a=%h b=%h", test_op, test_a, test_b);
                $display("  result=%h expected=%h", result, expected_result);
                $display("  flags Z/N/C/V=%b%b%b%b expected=%b%b%b%b",
                         zero, negative, carry, overflow,
                         expected_zero, expected_negative,
                         expected_carry, expected_overflow);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0s", test_name);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        a = 0;
        b = 0;
        alu_op = 0;

        // ADD: normal, zero, carry and signed-overflow cases.
        check(32'd5,          32'd7,          3'b000, 32'd12,         0, 0, "01 ADD normal");
        check(32'd0,          32'd0,          3'b000, 32'd0,          0, 0, "02 ADD zero");
        check(32'hFFFFFFFF,   32'd1,          3'b000, 32'd0,          1, 0, "03 ADD unsigned carry");
        check(32'h7FFFFFFF,   32'd1,          3'b000, 32'h80000000,  0, 1, "04 ADD positive overflow");
        check(32'h80000000,   32'hFFFFFFFF,   3'b000, 32'h7FFFFFFF,  1, 1, "05 ADD negative overflow");

        // SUB: normal, equality, borrow and signed-overflow cases.
        check(32'd9,          32'd4,          3'b001, 32'd5,          1, 0, "06 SUB normal");
        check(32'd4,          32'd4,          3'b001, 32'd0,          1, 0, "07 SUB equal");
        check(32'd3,          32'd5,          3'b001, 32'hFFFFFFFE,  0, 0, "08 SUB unsigned borrow");
        check(32'h80000000,   32'd1,          3'b001, 32'h7FFFFFFF,  1, 1, "09 SUB signed overflow");

        // Logical operations.
        check(32'hF0F0AA55,   32'h0FF00FF0,   3'b010, 32'h00F00A50,  0, 0, "10 AND");
        check(32'hF0000000,   32'h0000FFFF,   3'b011, 32'hF000FFFF,  0, 0, "11 OR");
        check(32'hAAAAAAAA,   32'hFFFFFFFF,   3'b100, 32'h55555555,  0, 0, "12 XOR");
        check(32'h12345678,   32'h12345678,   3'b100, 32'h00000000,  0, 0, "13 XOR zero result");

        // Signed set-less-than.
        check(32'hFFFFFFFF,   32'd1,          3'b101, 32'd1,         0, 0, "14 SLT negative less");
        check(32'd1,          32'hFFFFFFFF,   3'b101, 32'd0,         0, 0, "15 SLT positive greater");
        check(32'h80000000,   32'h7FFFFFFF,   3'b101, 32'd1,         0, 0, "16 SLT signed extremes");

        // Logical shifts: zero, one, middle and maximum shift amount.
        check(32'h80000001,   32'd0,          3'b110, 32'h80000001,  0, 0, "17 SLL by zero");
        check(32'h80000001,   32'd1,          3'b110, 32'h00000002,  1, 0, "18 SLL by one");
        check(32'h00000001,   32'd31,         3'b110, 32'h80000000,  0, 0, "19 SLL by 31");
        check(32'h80000001,   32'd0,          3'b111, 32'h80000001,  0, 0, "20 SRL by zero");
        check(32'h80000001,   32'd1,          3'b111, 32'h40000000,  1, 0, "21 SRL by one");
        check(32'h80000000,   32'd31,         3'b111, 32'h00000001,  0, 0, "22 SRL by 31");

        // Further corner and flag checks.
        check(32'hFFFFFFFF,   32'h00000000,   3'b010, 32'h00000000,  0, 0, "23 AND zero");
        check(32'h00000000,   32'hFFFFFFFF,   3'b011, 32'hFFFFFFFF,  0, 0, "24 OR all ones");
        check(32'h00000000,   32'h00000001,   3'b001, 32'hFFFFFFFF,  0, 0, "25 SUB negative result");

        #2;
        $display("----------------------------------------");
        $display("ALU TEST SUMMARY: PASS=%0d FAIL=%0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");
        $finish;
    end

endmodule
