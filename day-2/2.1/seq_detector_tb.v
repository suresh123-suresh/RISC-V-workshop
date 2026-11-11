`timescale 1ns/1ps
module seq_detector_tb;
    reg clk, reset, serial_in;
    wire moore_detected, mealy_detected;
    reg [31:0] history;
    integer bit_count, errors, detections_moore, detections_mealy;
    integer stream_index;

    seq_moore u_moore(clk, reset, serial_in, moore_detected);
    seq_mealy u_mealy(clk, reset, serial_in, mealy_detected);

    always #5 clk = ~clk;

    // Apply one serial bit on each falling edge and check after the active edge.
    task send_bit;
        input bit_value;
        reg expected;
        begin
            @(negedge clk);
            serial_in = bit_value;
            expected = 1'b0;
            history = {history[2:0], bit_value};
            if (bit_count >= 3)
                expected = (history[3:0] == 4'b1011);
            bit_count = bit_count + 1;
            // Mealy output is combinational: sample after input settles, before the clock edge.
            #1;
            if (mealy_detected !== expected) begin
                $display("MEALY FAIL stream=%0d bit=%0d input=%b out=%b expected=%b",
                         stream_index, bit_count, bit_value, mealy_detected, expected);
                errors = errors + 1;
            end
            if (mealy_detected) detections_mealy = detections_mealy + 1;

            // Moore output changes only after the state register captures this bit.
            @(posedge clk);
            #1;
            if (moore_detected !== expected) begin
                $display("MOORE FAIL stream=%0d bit=%0d input=%b out=%b expected=%b",
                         stream_index, bit_count, bit_value, moore_detected, expected);
                errors = errors + 1;
            end
            if (moore_detected) detections_moore = detections_moore + 1;
        end
    endtask

    task reset_detector;
        begin
            @(negedge clk);
            reset = 1'b1;
            serial_in = 1'b0;
            history = 0;
            bit_count = 0;
            @(negedge clk);
            reset = 1'b0;
        end
    endtask

    initial begin
        clk=0; reset=1; serial_in=0;
        history=0; bit_count=0; errors=0;
        detections_moore=0; detections_mealy=0; stream_index=0;
        repeat (2) @(negedge clk);
        reset=0;

        // Stream 1: one detection.
        stream_index=1;
        send_bit(1); send_bit(0); send_bit(1); send_bit(1);
        send_bit(0); send_bit(0);

        // Stream 2: overlapping detections in 1011011.
        reset_detector();
        stream_index=2;
        send_bit(1); send_bit(0); send_bit(1); send_bit(1);
        send_bit(0); send_bit(1); send_bit(1);

        // Stream 3: noise, then multiple separated detections.
        reset_detector();
        stream_index=3;
        send_bit(0); send_bit(1); send_bit(1); send_bit(0);
        send_bit(1); send_bit(1); send_bit(0); send_bit(1);
        send_bit(1);

        if (errors == 0)
            $display("ACTIVITY 2.1 PASS: Moore and Mealy detectors matched reference for all streams");
        else
            $display("ACTIVITY 2.1 FAIL: %0d mismatches", errors);
        $display("Moore detections=%0d, Mealy detections=%0d",
                 detections_moore, detections_mealy);
        $finish;
    end
endmodule
