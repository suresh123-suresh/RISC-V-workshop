
`timescale 1ns/1ps

module d_tb;

reg [3:0] d;
reg clk;
reg rst;
wire [3:0] q;

// DUT instantiation
d_flip_flop uut(d, clk, rst, q);

// Clock generation
always #5 clk = ~clk;

// Test stimulus
initial begin
    clk = 0;
    rst = 1;
    d = 4'b0000;

    #10 rst = 0;

    #10 d = 4'b0001;
    #10 d = 4'b0010;
    #10 d = 4'b0011;
    #10 d = 4'b0100;
    #10 d = 4'b0101;

    #10 $finish;
end

// Monitor
initial begin
    $monitor("d = %b | clk = %b | rst = %b | q = %b",
              d, clk, rst, q);
end

endmodule
