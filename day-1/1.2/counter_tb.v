`timescale 1ns/1ps

module counter_tb;

    reg clk;
    reg reset;
    reg enable;
    reg up_down;
    reg load;
    reg [7:0] load_data;
    wire [7:0] count;

    integer pass_count;
    integer fail_count;

    counter dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .up_down(up_down),
        .load(load),
        .load_data(load_data),
        .count(count)
    );

    // 10 ns clock period.
    always #5 clk = ~clk;

    task check_count;
        input [7:0] expected;
        input [8*40-1:0] test_name;
        begin
            if (count !== expected) begin
                $display("FAIL: %0s | got=%h expected=%h",
                         test_name, count, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %0s | count=%h", test_name, count);
                pass_count = pass_count + 1;
            end
        end
    endtask

    // Drive controls away from the active edge, then sample after it.
    task apply_cycle;
        input rst;
        input en;
        input direction;
        input ld;
        input [7:0] data;
        begin
            @(negedge clk);
            reset = rst;
            enable = en;
            up_down = direction;
            load = ld;
            load_data = data;
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b0;
        enable = 1'b0;
        up_down = 1'b1;
        load = 1'b0;
        load_data = 8'd0;
        pass_count = 0;
        fail_count = 0;

        // Synchronous reset.
        apply_cycle(1'b1, 1'b0, 1'b1, 1'b0, 8'd0);
        check_count(8'd0, "01 synchronous reset");

        // Count up for three cycles.
        apply_cycle(1'b0, 1'b1, 1'b1, 1'b0, 8'd0);
        check_count(8'd1, "02 count up to 1");
        apply_cycle(1'b0, 1'b1, 1'b1, 1'b0, 8'd0);
        check_count(8'd2, "03 count up to 2");
        apply_cycle(1'b0, 1'b1, 1'b1, 1'b0, 8'd0);
        check_count(8'd3, "04 count up to 3");

        // Count down.
        apply_cycle(1'b0, 1'b1, 1'b0, 1'b0, 8'd0);
        check_count(8'd2, "05 count down");

        // Parallel load.
        apply_cycle(1'b0, 1'b0, 1'b1, 1'b1, 8'hA5);
        check_count(8'hA5, "06 parallel load");

        // Hold when enable is low.
        apply_cycle(1'b0, 1'b0, 1'b1, 1'b0, 8'h00);
        check_count(8'hA5, "07 hold when disabled");

        // Load takes priority over enable.
        apply_cycle(1'b0, 1'b1, 1'b1, 1'b1, 8'hFE);
        check_count(8'hFE, "08 load priority over enable");

        // Overflow wraparound: FF + 1 = 00.
        apply_cycle(1'b0, 1'b1, 1'b1, 1'b0, 8'h00);
        check_count(8'hFF, "09 count up to FF");
        apply_cycle(1'b0, 1'b1, 1'b1, 1'b0, 8'h00);
        check_count(8'h00, "10 up-counter wraparound");

        // Underflow wraparound: 00 - 1 = FF.
        apply_cycle(1'b0, 1'b1, 1'b0, 1'b0, 8'h00);
        check_count(8'hFF, "11 down-counter wraparound");

        // Reset takes priority over load and enable.
        apply_cycle(1'b1, 1'b1, 1'b1, 1'b1, 8'h77);
        check_count(8'h00, "12 reset priority");

        $display("----------------------------------------");
        $display("COUNTER TEST SUMMARY: PASS=%0d FAIL=%0d",
                 pass_count, fail_count);
        if (fail_count == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");
        $finish;
    end

endmodule
