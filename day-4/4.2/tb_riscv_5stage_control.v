`timescale 1ns/1ps
module tb_riscv_5stage_control;
    reg clk=0;
    reg reset=1;
    integer i, errors, cycles;

    riscv_5stage dut(.clk(clk), .reset(reset));
    always #5 clk=~clk;

    task check_reg;
        input integer idx;
        input [31:0] exp;
        input [8*24-1:0] label_text;
        begin
            if (dut.registers[idx] !== exp) begin
                $display("FAIL: %0s x%0d=%0d expected=%0d",
                         label_text,idx,dut.registers[idx],exp);
                errors=errors+1;
            end else
                $display("PASS: %0s x%0d=%0d",label_text,idx,dut.registers[idx]);
        end
    endtask

    initial begin
        errors=0;
        for(i=0;i<64;i=i+1) begin
            dut.instruction_mem[i]=32'h00000013;
            dut.data_mem[i]=0;
        end
        $readmemh("programs/control_hazard_test.hex",dut.instruction_mem);
        repeat(2) @(posedge clk);
        #1 reset=0;

        cycles=0;
        while((cycles<80) && (dut.pc != 32'd36)) begin
            @(posedge clk); #1; cycles=cycles+1;
        end
        repeat(6) @(posedge clk);
        #1;

        check_reg(1,32'd5,"Setup instruction");
        check_reg(2,32'd0,"Taken branch flush");
        check_reg(3,32'd7,"Not-taken branch path");
        check_reg(4,32'd9,"Not-taken branch continues");
        check_reg(5,32'd11,"JAL target executes");
        check_reg(6,32'd28,"JAL link address");
        check_reg(7,32'd0,"JAL wrong-path flush");

        if(errors==0)
            $display("DAY 4 ACTIVITY 4.2: CONTROL HAZARD TESTS PASSED");
        else
            $display("DAY 4 ACTIVITY 4.2: FAILED with %0d error(s)",errors);
        $finish;
    end
endmodule
