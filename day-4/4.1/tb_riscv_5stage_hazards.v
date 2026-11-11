`timescale 1ns/1ps

module tb_riscv_5stage_hazards;
    reg clk = 0;
    reg reset = 1;
    integer i;
    integer errors;
    integer cycles;

    riscv_5stage dut (.clk(clk), .reset(reset));
    always #5 clk = ~clk;

    task check_reg;
        input integer index;
        input [31:0] expected;
        input [8*24-1:0] label_text;
        begin
            if (dut.registers[index] !== expected) begin
                $display("FAIL: %0s x%0d=%0d expected=%0d",
                         label_text, index, dut.registers[index], expected);
                errors = errors + 1;
            end else
                $display("PASS: %0s x%0d=%0d", label_text, index, dut.registers[index]);
        end
    endtask

    task check_mem;
        input integer index;
        input [31:0] expected;
        input [8*24-1:0] label_text;
        begin
            if (dut.data_mem[index] !== expected) begin
                $display("FAIL: %0s data_mem[%0d]=%0d expected=%0d",
                         label_text, index, dut.data_mem[index], expected);
                errors = errors + 1;
            end else
                $display("PASS: %0s data_mem[%0d]=%0d",
                         label_text, index, dut.data_mem[index]);
        end
    endtask

    initial begin
        errors = 0;
        for (i=0; i<64; i=i+1) begin
            dut.instruction_mem[i] = 32'h00000013;
            dut.data_mem[i] = 0;
        end
        $readmemh("programs/hazard_test.hex", dut.instruction_mem);

        repeat (2) @(posedge clk);
        #1 reset = 0;

        // The terminal self-loop should be reached well within this bound.
        cycles = 0;
        while ((cycles < 80) && !(dut.pc == 32'd48)) begin
            @(posedge clk);
            #1;
            cycles = cycles + 1;
        end
        repeat (5) @(posedge clk);
        #1;

        check_reg(1, 32'd5,  "Initial producer");
        check_reg(2, 32'd8,  "EX/MEM forwarding");
        check_reg(3, 32'd13, "Forwarded operands");
        check_reg(5, 32'd13, "Load result");
        check_reg(6, 32'd26, "Load-use dependency");
        check_reg(7, 32'd99, "Instruction before branch");
        check_reg(8, 32'd0,  "Wrong-path instruction flushed");
        check_reg(9, 32'd42, "Branch target instruction");
        check_mem(0, 32'd13, "Store result");
        check_mem(1, 32'd26, "Store forwarded load-use result");

        if (errors == 0)
            $display("DAY 4 ACTIVITY 4.1: ALL HAZARD CHECKS PASSED");
        else
            $display("DAY 4 ACTIVITY 4.1: FAILED with %0d error(s)", errors);
        $finish;
    end
endmodule
