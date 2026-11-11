`timescale 1ns/1ps

module shifter_tb;

    reg  [31:0] data_in;
    reg  [4:0]  shamt;
    reg  [1:0]  mode;
    wire [31:0] data_out;

    integer shift_index;
    integer mode_index;
    integer pass_count;
    integer fail_count;

    reg [31:0] expected;

    shifter dut (
        .data_in(data_in),
        .shamt(shamt),
        .mode(mode),
        .data_out(data_out)
    );

    // Compare DUT output with the corresponding Verilog reference operator.
    task check_shift;
        input [31:0] test_data;
        input [4:0]  test_shamt;
        input [1:0]  test_mode;
        input [31:0] reference_result;
        begin
            data_in = test_data;
            shamt = test_shamt;
            mode = test_mode;
            expected = reference_result;
            #1;

            if (data_out !== expected) begin
                $display("FAIL: mode=%b shamt=%0d data=%h got=%h expected=%h",
                         test_mode, test_shamt, test_data, data_out, expected);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        data_in = 32'b0;
        shamt = 5'd0;
        mode = 2'b00;

        // The PDF requires checking every shift amount from 0 through 31.
        // Exercise all three supported shift modes for each amount.
        for (shift_index = 0; shift_index < 32; shift_index = shift_index + 1) begin
            check_shift(32'h81234567, shift_index, 2'b00,
                        (32'h81234567 << shift_index));
            check_shift(32'h81234567, shift_index, 2'b01,
                        (32'h81234567 >> shift_index));
            check_shift(32'h81234567, shift_index, 2'b10,
                        ($signed(32'h81234567) >>> shift_index));
        end

        // Extra directed patterns to exercise zeros, ones and sign extension.
        check_shift(32'h00000000, 5'd0,  2'b00, 32'h00000000);
        check_shift(32'hFFFFFFFF, 5'd0,  2'b01, 32'hFFFFFFFF);
        check_shift(32'hFFFFFFFF, 5'd31, 2'b01, 32'h00000001);
        check_shift(32'h80000000, 5'd1,  2'b10, 32'hC0000000);
        check_shift(32'h7FFFFFFF, 5'd4,  2'b10, 32'h07FFFFFF);
        check_shift(32'h12345678, 5'd8,  2'b00, 32'h34567800);

        // Reserved mode must produce zero.
        check_shift(32'hDEADBEEF, 5'd7, 2'b11, 32'h00000000);

        $display("----------------------------------------");
        $display("SHIFTER TEST SUMMARY: PASS=%0d FAIL=%0d",
                 pass_count, fail_count);
        if (fail_count == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");
        $finish;
    end

endmodule
