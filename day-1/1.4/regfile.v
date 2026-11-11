`timescale 1ns/1ps

// Activity 1.4: 32 x 32 register file.
// Two asynchronous read ports, one synchronous write port.
// Register x0 is hardwired to zero.
// Same-cycle write/read to the same nonzero address is bypassed from wd.
module regfile (
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  wa,
    input  wire [4:0]  ra1,
    input  wire [4:0]  ra2,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);

    reg [31:0] registers [1:31];

    // Synchronous write. Address zero is deliberately excluded.
    always @(posedge clk) begin
        if (we && (wa != 5'd0))
            registers[wa] <= wd;
    end

    // Asynchronous reads with same-cycle write-through bypass.
    assign rd1 = (ra1 == 5'd0) ? 32'd0 :
                 ((we && (wa == ra1)) ? wd : registers[ra1]);

    assign rd2 = (ra2 == 5'd0) ? 32'd0 :
                 ((we && (wa == ra2)) ? wd : registers[ra2]);

endmodule
