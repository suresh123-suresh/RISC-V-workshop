`timescale 1ns/1ps

module elevator_tb;

reg [2:0] a;
reg clk, rst;

wire [2:0] q;
wire up, down;
wire [2:0] reached;

// DUT instantiation
elevator uut (
    .a(a),
    .clk(clk),
    .rst(rst),
    .q(q),
    .up(up),
    .down(down),
    .reached(reached)
);


always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    a = 3'b000;

    #10 rst = 0;

    #10 a = 3'd4;


    #60 a = 3'd2;


    #40 a = 3'd0;


    #40 a = 3'd3;

#60 $finish;
end


initial begin
    $monitor("Time=%0t | Requested Floor(a)=%0d | Current Floor(q)=%0d | UP=%b | DOWN=%b | REACHED=%0d",
             $time, a, q, up, down, reached);
end

endmodule
