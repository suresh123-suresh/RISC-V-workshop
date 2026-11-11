`timescale 1ns/1ps
module adder_sub_tb;
    reg [7:0] a, b;
    reg mode;
    wire [7:0] result;
    wire carry_out, overflow;
    reg [7:0] expected;
    reg expected_overflow;
    integer i, j, m, errors;
    reg signed [8:0] signed_calc;

    adder_sub dut (
        .a(a), .b(b), .mode(mode),
        .result(result), .carry_out(carry_out), .overflow(overflow)
    );

    initial begin
        errors = 0;
        // Exhaustive verification: all 256 x 256 operand pairs in both modes.
        for (m = 0; m < 2; m = m + 1) begin
            mode = m[0];
            for (i = 0; i < 256; i = i + 1) begin
                for (j = 0; j < 256; j = j + 1) begin
                    a = i;
                    b = j;
                    #1;
                    if (mode == 1'b0) begin
                        expected = a + b;
                        signed_calc = $signed({a[7],a}) + $signed({b[7],b});
                    end else begin
                        expected = a - b;
                        signed_calc = $signed({a[7],a}) - $signed({b[7],b});
                    end
                    expected_overflow = (signed_calc > 127) || (signed_calc < -128);
                    if (result !== expected || overflow !== expected_overflow) begin
                        if (errors < 10)
                            $display("FAIL mode=%b a=%h b=%h result=%h expected=%h ovf=%b expected_ovf=%b",
                                     mode, a, b, result, expected, overflow, expected_overflow);
                        errors = errors + 1;
                    end
                end
            end
        end
        if (errors == 0)
            $display("ACTIVITY 1.5 PASS: 131072 exhaustive operand/mode tests");
        else
            $display("ACTIVITY 1.5 FAIL: %0d mismatches", errors);
        $finish;
    end
endmodule
