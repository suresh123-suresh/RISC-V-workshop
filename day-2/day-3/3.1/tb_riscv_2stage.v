`timescale 1ns/1ps

module tb_riscv_2stage;

    reg clk;
    reg reset;

    riscv_2stage dut (.clk(clk), .reset(reset));
    always #5 clk = ~clk;

    function [31:0] enc_i;
        input integer imm;
        input integer rs1;
        input integer funct3;
        input integer rd;
        input [6:0] opcode;
        begin
            enc_i = {imm[11:0], rs1[4:0], funct3[2:0], rd[4:0], opcode};
        end
    endfunction

    function [31:0] enc_u;
        input [19:0] imm20;
        input integer rd;
        input [6:0] opcode;
        begin
            enc_u = {imm20, rd[4:0], opcode};
        end
    endfunction

    function [31:0] enc_j;
        input integer offset;
        input integer rd;
        reg [20:0] j;
        begin
            j = offset;
            enc_j = {j[20], j[10:1], j[11], j[19:12], rd[4:0], 7'b1101111};
        end
    endfunction

    integer k;
    integer errors;

    task check_reg;
        input integer index;
        input [31:0] expected;
        input [8*24-1:0] label_text;
        begin
            if (dut.registers[index] !== expected) begin
                $display("FAIL: %0s x%0d = %h, expected %h",
                         label_text, index, dut.registers[index], expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s x%0d = %h",
                         label_text, index, dut.registers[index]);
            end
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        errors = 0;

        for (k = 0; k < 64; k = k + 1) begin
            dut.instruction_mem[k] = 32'h00000013; // NOP
            dut.data_mem[k] = 32'd0;
        end

        // Independent immediate operations from x0:
        // ANDI x1,x0,255  -> 0
        // ORI  x2,x0,85   -> 85
        // XORI x3,x0,90   -> 90
        // SLTI x4,x0,1    -> 1
        // SLTI x5,x0,-1   -> 0 (signed 0 < -1 is false)
        dut.instruction_mem[0] = enc_i(255, 0, 3'b111, 1, 7'b0010011);
        dut.instruction_mem[1] = enc_i(85,  0, 3'b110, 2, 7'b0010011);
        dut.instruction_mem[2] = enc_i(90,  0, 3'b100, 3, 7'b0010011);
        dut.instruction_mem[3] = enc_i(1,   0, 3'b010, 4, 7'b0010011);
        dut.instruction_mem[4] = enc_i(-1,  0, 3'b010, 5, 7'b0010011);

        // LUI x10,0x12345 -> 0x12345000
        // SLLI x11,x10,4  -> 0x23450000
        // SRLI x12,x10,4  -> 0x01234500
        dut.instruction_mem[5] = enc_u(20'h12345, 10, 7'b0110111);
        dut.instruction_mem[6] = enc_i(4, 10, 3'b001, 11, 7'b0010011);
        dut.instruction_mem[7] = enc_i(4, 10, 3'b101, 12, 7'b0010011);

        // JAL at byte address 32 jumps +8 to byte address 40.
        // x13 receives return address 36; x14 must be skipped.
        dut.instruction_mem[8]  = enc_j(8, 13);
        dut.instruction_mem[9]  = enc_i(99, 0, 3'b000, 14, 7'b0010011);
        dut.instruction_mem[10] = enc_i(7, 0, 3'b000, 15, 7'b0010011);

        #12;
        reset = 0;

        repeat (20) @(posedge clk);
        #1;

        $display("----------------------------------------------");
        $display(" Day 3 Activity 3.1 - 2-Stage CPU Test Results");
        $display("----------------------------------------------");

        check_reg(1,  32'd0,          "ANDI");
        check_reg(2,  32'd85,         "ORI");
        check_reg(3,  32'd90,         "XORI");
        check_reg(4,  32'd1,          "SLTI positive");
        check_reg(5,  32'd0,          "SLTI signed");
        check_reg(10, 32'h12345000,   "LUI");
        check_reg(11, 32'h23450000,   "SLLI");
        check_reg(12, 32'h01234500,   "SRLI");
        check_reg(13, 32'd36,         "JAL link");
        check_reg(14, 32'd0,          "JAL flush");
        check_reg(15, 32'd7,          "JAL target");

        if (errors == 0)
            $display("ACTIVITY 3.1 TEST PASSED");
        else
            $display("ACTIVITY 3.1 TEST FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
