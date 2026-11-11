`timescale 1ns/1ps

module tb_riscv_day3_programs;
    reg clk = 0;
    reg reset = 1;
    integer i;
    integer errors;

    riscv_2stage dut (.clk(clk), .reset(reset));
    always #5 clk = ~clk;

    task clear_program_and_registers;
        integer j;
        begin
            for (j=0; j<64; j=j+1)
                dut.instruction_mem[j] = 32'h00000013;
            for (j=0; j<32; j=j+1)
                dut.registers[j] = 0;
            reset = 1;
            repeat (2) @(posedge clk);
            #1 reset = 0;
        end
    endtask

    task check_word;
        input integer address;
        input [31:0] expected;
        input [8*32-1:0] label_text;
        begin
            if (dut.data_mem[address] !== expected) begin
                $display("FAIL: %0s data_mem[%0d]=%0d expected=%0d",
                         label_text, address, dut.data_mem[address], expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s data_mem[%0d]=%0d",
                         label_text, address, dut.data_mem[address]);
            end
        end
    endtask

    initial begin
        errors = 0;
        for (i=0; i<64; i=i+1) begin
            dut.instruction_mem[i] = 32'h00000013;
            dut.data_mem[i] = 0;
        end

        // PROGRAM 1: sum 1 through 10; expected 55 at byte address 0.
        $readmemh("programs/program1.hex", dut.instruction_mem);
        clear_program_and_registers();
        repeat (70) @(posedge clk);
        #1;
        check_word(0, 32'd55, "Program 1 sum 1..10");

        // PROGRAM 2: first ten Fibonacci values at data_mem[0:9].
        $readmemh("programs/program2.hex", dut.instruction_mem);
        clear_program_and_registers();
        for (i=0; i<10; i=i+1)
            dut.data_mem[i] = 0;
        repeat (90) @(posedge clk);
        #1;
        check_word(0,  32'd0,  "Fibonacci F0");
        check_word(1,  32'd1,  "Fibonacci F1");
        check_word(2,  32'd1,  "Fibonacci F2");
        check_word(3,  32'd2,  "Fibonacci F3");
        check_word(4,  32'd3,  "Fibonacci F4");
        check_word(5,  32'd5,  "Fibonacci F5");
        check_word(6,  32'd8,  "Fibonacci F6");
        check_word(7, 32'd13,  "Fibonacci F7");
        check_word(8, 32'd21,  "Fibonacci F8");
        check_word(9, 32'd34,  "Fibonacci F9");

        // PROGRAM 3: max of [12, 7, 25, 3, 19, 42, 8, 31].
        // Result is stored at byte address 32 => data_mem[8].
        $readmemh("programs/program3.hex", dut.instruction_mem);
        clear_program_and_registers();
        dut.data_mem[0] = 12;
        dut.data_mem[1] = 7;
        dut.data_mem[2] = 25;
        dut.data_mem[3] = 3;
        dut.data_mem[4] = 19;
        dut.data_mem[5] = 42;
        dut.data_mem[6] = 8;
        dut.data_mem[7] = 31;
        repeat (100) @(posedge clk);
        #1;
        check_word(8, 32'd42, "Program 3 maximum of array");

        if (errors == 0)
            $display("DAY 3 ACTIVITY 3.2: ALL PROGRAMS PASSED");
        else
            $display("DAY 3 ACTIVITY 3.2: FAILED with %0d error(s)", errors);
        $finish;
    end
endmodule
