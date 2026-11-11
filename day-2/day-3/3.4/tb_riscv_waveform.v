`timescale 1ns/1ps

module tb_riscv_waveform;
    reg clk = 0;
    reg reset = 1;
    integer i;

    riscv_2stage dut (.clk(clk), .reset(reset));
    always #5 clk = ~clk;

    initial begin
        for (i=0; i<64; i=i+1) begin
            dut.instruction_mem[i] = 32'h00000013;
            dut.data_mem[i] = 0;
        end
        $readmemh("programs/program1.hex", dut.instruction_mem);

        repeat (2) @(posedge clk);
        #1 reset = 0;

        // Run long enough for the loop to finish and store the sum.
        repeat (90) @(posedge clk);
        #1;
        if (dut.data_mem[0] === 32'd55)
            $display("PASS: Program 1 stored sum 55 in data_mem[0]");
        else
            $display("FAIL: data_mem[0]=%0d, expected 55", dut.data_mem[0]);
        $finish;
    end
endmodule
