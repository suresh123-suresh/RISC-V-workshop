`timescale 1ns/1ps

module regfile_tb;

    reg clk;
    reg we;
    reg [4:0] wa;
    reg [4:0] ra1;
    reg [4:0] ra2;
    reg [31:0] wd;
    wire [31:0] rd1;
    wire [31:0] rd2;

    reg [31:0] reference_regs [0:31];

    integer i;
    integer pass_count;
    integer fail_count;
    reg [31:0] random_state;
    reg [4:0] random_wa;
    reg [4:0] random_ra1;
    reg [4:0] random_ra2;
    reg [31:0] random_wd;
    reg random_we;

    regfile dut (
        .clk(clk),
        .we(we),
        .wa(wa),
        .ra1(ra1),
        .ra2(ra2),
        .wd(wd),
        .rd1(rd1),
        .rd2(rd2)
    );

    always #5 clk = ~clk;

    // Compare both read ports against the software reference model.
    // This task also models the write-through bypass while we is asserted.
    task check_reads;
        input [8*48-1:0] label;
        reg [31:0] expected1;
        reg [31:0] expected2;
        begin
            expected1 = (ra1 == 0) ? 32'd0 : reference_regs[ra1];
            expected2 = (ra2 == 0) ? 32'd0 : reference_regs[ra2];

            if (we && (wa != 0) && (wa == ra1))
                expected1 = wd;
            if (we && (wa != 0) && (wa == ra2))
                expected2 = wd;

            #1;
            if ((rd1 !== expected1) || (rd2 !== expected2)) begin
                $display("FAIL: %0s", label);
                $display("  ra1=%0d rd1=%h expected1=%h", ra1, rd1, expected1);
                $display("  ra2=%0d rd2=%h expected2=%h", ra2, rd2, expected2);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    // Drive one transaction away from the active edge, check bypass,
    // commit the write at the rising edge, update the reference model,
    // then check the stored value with write enable deasserted.
    task transact;
        input write_enable;
        input [4:0] write_addr;
        input [31:0] write_data;
        input [4:0] read_addr1;
        input [4:0] read_addr2;
        input [8*48-1:0] label;
        begin
            @(negedge clk);
            we = write_enable;
            wa = write_addr;
            wd = write_data;
            ra1 = read_addr1;
            ra2 = read_addr2;

            check_reads({label, " bypass/read"});
            @(posedge clk);
            if (write_enable && (write_addr != 0))
                reference_regs[write_addr] = write_data;
            #1;
            we = 1'b0;
            check_reads({label, " stored/read"});
        end
    endtask

    initial begin
        clk = 1'b0;
        we = 1'b0;
        wa = 5'd0;
        ra1 = 5'd0;
        ra2 = 5'd0;
        wd = 32'd0;
        pass_count = 0;
        fail_count = 0;
        random_state = 32'h5A17C9E3;

        // Reference model starts at zero. The DUT registers are initialized
        // through legal writes below, avoiding reliance on RTL power-up values.
        for (i = 0; i < 32; i = i + 1)
            reference_regs[i] = 32'd0;

        // Check x0 reads as zero and cannot be overwritten.
        transact(1'b1, 5'd0, 32'hDEADBEEF, 5'd0, 5'd0, "x0 write ignored");
        transact(1'b0, 5'd0, 32'd0, 5'd0, 5'd0, "x0 remains zero");

        // Initialize x1 through x31 using real write transactions.
        for (i = 1; i < 32; i = i + 1)
            transact(1'b1, i[4:0], (32'h10000000 + i),
                     i[4:0], 5'd0, "initialize register");

        // Directed same-cycle bypass to each read port.
        transact(1'b1, 5'd5, 32'h12345678, 5'd5, 5'd5, "same-cycle bypass both ports");
        transact(1'b1, 5'd6, 32'hCAFEBABE, 5'd6, 5'd5, "bypass read port one");
        transact(1'b1, 5'd7, 32'h0BADF00D, 5'd5, 5'd7, "bypass read port two");

        // Back-to-back writes to the same address with different data.
        transact(1'b1, 5'd9, 32'hAAAAAAAA, 5'd9, 5'd0, "back-to-back write one");
        transact(1'b1, 5'd9, 32'h55555555, 5'd9, 5'd9, "back-to-back write two");
        transact(1'b0, 5'd0, 32'd0, 5'd9, 5'd9, "verify latest back-to-back write");

        // At least 200 deterministic pseudo-random read/write operations.
        for (i = 0; i < 200; i = i + 1) begin
            random_state = random_state * 32'd1664525 + 32'd1013904223;
            random_wa = random_state[4:0];
            random_ra1 = random_state[9:5];
            random_ra2 = random_state[14:10];
            random_wd = random_state ^ (32'hA5A50000 + i);
            random_we = random_state[20];
            transact(random_we, random_wa, random_wd,
                     random_ra1, random_ra2, "random operation");
        end

        // Final x0 check.
        transact(1'b0, 5'd0, 32'd0, 5'd0, 5'd31, "final x0 and register read");

        $display("----------------------------------------");
        $display("REGISTER FILE TEST SUMMARY: PASS=%0d FAIL=%0d",
                 pass_count, fail_count);
        if (fail_count == 0)
            $display("OVERALL RESULT: PASS");
        else
            $display("OVERALL RESULT: FAIL");
        $finish;
    end

endmodule
