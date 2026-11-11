`timescale 1ns/1ps
module vending_tb;
    reg clk, reset, coin5, coin10, cancel;
    wire dispense;
    wire [4:0] change, refund;
    integer errors;

    vending dut (
        .clk(clk), .reset(reset),
        .coin5(coin5), .coin10(coin10), .cancel(cancel),
        .dispense(dispense), .change(change), .refund(refund)
    );

    always #5 clk = ~clk;

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task clear_inputs;
        begin
            coin5=0; coin10=0; cancel=0;
        end
    endtask

    task check_outputs;
        input expected_dispense;
        input [4:0] expected_change;
        input [4:0] expected_refund;
        input [255:0] test_name;
        begin
            if (dispense !== expected_dispense ||
                change !== expected_change ||
                refund !== expected_refund) begin
                $display("FAIL %0s: dispense=%b change=%0d refund=%0d; expected %b/%0d/%0d",
                         test_name, dispense, change, refund,
                         expected_dispense, expected_change, expected_refund);
                errors = errors + 1;
            end else begin
                $display("PASS %0s", test_name);
            end
        end
    endtask

    initial begin
        clk=0; reset=1; errors=0;
        clear_inputs();
        tick();
        reset=0;

        // Transition: IDLE + Rs.5 -> CREDIT5.
        coin5=1; tick(); clear_inputs();
        check_outputs(0, 0, 0, "Rs.5 accepted; no vend");

        // Transition: CREDIT5 + Rs.5 -> CREDIT10.
        coin5=1; tick(); clear_inputs();
        check_outputs(0, 0, 0, "second Rs.5 accepted; total Rs.10");

        // Transition: CREDIT10 + Rs.5 -> vend at exact price.
        coin5=1; tick(); clear_inputs();
        check_outputs(1, 0, 0, "Rs.15 exact payment dispenses item");

        // Transition: IDLE + Rs.10 -> CREDIT10; then Rs.5 -> vend.
        coin10=1; tick(); clear_inputs();
        check_outputs(0, 0, 0, "Rs.10 accepted");
        coin5=1; tick(); clear_inputs();
        check_outputs(1, 0, 0, "Rs.10 plus Rs.5 dispenses item");

        // Overpayment: Rs.10 + Rs.10 -> vend and return Rs.5 change.
        coin10=1; tick(); clear_inputs();
        check_outputs(0, 0, 0, "first Rs.10 accepted");
        coin10=1; tick(); clear_inputs();
        check_outputs(1, 5, 0, "Rs.20 payment returns Rs.5 change");

        // Cancel from CREDIT5 refunds Rs.5.
        coin5=1; tick(); clear_inputs();
        cancel=1; tick(); clear_inputs();
        check_outputs(0, 0, 5, "cancel refunds Rs.5");

        // Cancel from CREDIT10 refunds Rs.10.
        coin10=1; tick(); clear_inputs();
        cancel=1; tick(); clear_inputs();
        check_outputs(0, 0, 10, "cancel refunds Rs.10");

        // Cancel while idle refunds zero and does not dispense.
        cancel=1; tick(); clear_inputs();
        check_outputs(0, 0, 0, "cancel while idle returns zero");

        // Verify outputs return low/zero on the next idle cycle.
        tick();
        check_outputs(0, 0, 0, "transaction outputs are one-cycle pulses");

        if (errors == 0)
            $display("ACTIVITY 2.2 PASS: all directed vending transitions verified");
        else
            $display("ACTIVITY 2.2 FAIL: %0d errors", errors);
        $finish;
    end
endmodule
