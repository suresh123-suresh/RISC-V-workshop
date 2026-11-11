`timescale 1ns/1ps

module cpu_tb;
    reg clk;
    reg reset;
    integer errors;
    integer i;
    integer timeout_count;

    riscv_2stage dut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    // Run until the terminal JAL x0,0 redirects the PC back to itself.
    // This CPU has no architectural HALT instruction or done output.
    task run_until_halt;
        input [31:0] halt_pc;
        input integer max_cycles;
        integer cycles;
        reg halted;
        begin
            cycles = 0;
            halted = 0;
            while ((cycles < max_cycles) && !halted) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
                if ((dut.pc == halt_pc) &&
                    (dut.if_id_instruction == 32'h00000013))
                    halted = 1;
            end
            if (halted)
                $display("Program reached terminal JAL at PC=0x%08h after %0d cycles",
                         halt_pc, cycles);
            else begin
                $display("FAIL: timeout waiting for terminal JAL at PC=0x%08h",
                         halt_pc);
                errors = errors + 1;
            end
        end
    endtask

    task reset_cpu;
        integer j;
        begin
            reset = 1;
            repeat (2) @(posedge clk);
            #1;
            reset = 0;
        end
    endtask

    task check_mem;
        input integer word_index;
        input [31:0] expected;
        input [8*32-1:0] description;
        begin
            if (dut.data_mem[word_index] !== expected) begin
                $display("FAIL: %0s: data_mem[%0d]=%0d (0x%08h), expected %0d (0x%08h)",
                         description, word_index, dut.data_mem[word_index],
                         dut.data_mem[word_index], expected, expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s: data_mem[%0d]=%0d (0x%08h)",
                         description, word_index, dut.data_mem[word_index],
                         dut.data_mem[word_index]);
            end
        end
    endtask

    task clear_instruction_memory;
        integer j;
        begin
            for (j=0; j<64; j=j+1)
                dut.instruction_mem[j] = 32'h00000013; // NOP
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        errors = 0;

        for (i=0; i<64; i=i+1) begin
            dut.instruction_mem[i] = 32'h00000013;
            dut.data_mem[i] = 0;
        end

        // ---------------------------------------------------------
        // Program 1: Sum of integers 1 through 10.
        // Expected result: 55 at data memory word 0.
        // ---------------------------------------------------------
        $display("\n========== PROGRAM 1: SUM 1 TO 10 ==========");
        clear_instruction_memory();
        $readmemh("programs/program1.hex", dut.instruction_mem);
        reset_cpu();
        run_until_halt(32'd40, 100);
        check_mem(0, 32'd55, "Sum 1..10");

        // ---------------------------------------------------------
        // Program 2: First ten Fibonacci numbers.
        // Expected words: 0,1,1,2,3,5,8,13,21,34.
        // ---------------------------------------------------------
        $display("\n========== PROGRAM 2: FIBONACCI ==========");
        clear_instruction_memory();
        for (i=0; i<10; i=i+1)
            dut.data_mem[i] = 0;
        $readmemh("programs/program2.hex", dut.instruction_mem);
        reset_cpu();
        run_until_halt(32'd52, 150);
        check_mem(0, 32'd0,  "Fibonacci F0");
        check_mem(1, 32'd1,  "Fibonacci F1");
        check_mem(2, 32'd1,  "Fibonacci F2");
        check_mem(3, 32'd2,  "Fibonacci F3");
        check_mem(4, 32'd3,  "Fibonacci F4");
        check_mem(5, 32'd5,  "Fibonacci F5");
        check_mem(6, 32'd8,  "Fibonacci F6");
        check_mem(7, 32'd13, "Fibonacci F7");
        check_mem(8, 32'd21, "Fibonacci F8");
        check_mem(9, 32'd34, "Fibonacci F9");

        // ---------------------------------------------------------
        // Program 3: Maximum of eight words.
        // Input: 12,7,25,3,19,42,8,31.
        // Expected maximum: 42 at data memory word 8 (byte address 32).
        // ---------------------------------------------------------
        $display("\n========== PROGRAM 3: ARRAY MAXIMUM ==========");
        clear_instruction_memory();
        dut.data_mem[0] = 32'd12;
        dut.data_mem[1] = 32'd7;
        dut.data_mem[2] = 32'd25;
        dut.data_mem[3] = 32'd3;
        dut.data_mem[4] = 32'd19;
        dut.data_mem[5] = 32'd42;
        dut.data_mem[6] = 32'd8;
        dut.data_mem[7] = 32'd31;
        $readmemh("programs/program3.hex", dut.instruction_mem);
        reset_cpu();
        run_until_halt(32'd156, 200);
        check_mem(8, 32'd42, "Maximum of eight array values");

        $display("\n==============================================");
        if (errors == 0)
            $display("ACTIVITY 3.3: ALL THREE PROGRAMS PASSED");
        else
            $display("ACTIVITY 3.3: FAILED — %0d error(s)", errors);
        $display("==============================================\n");
        $finish;
    end
endmodule
