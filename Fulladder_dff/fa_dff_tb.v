
`timescale 1ns/1ps

module fa_dff_tb;

reg [3:0] a, b;
reg cin;
reg clk, rst;

wire [3:0] q;
wire cout;

integer i, j, k;


fa_dff uut (
    .a(a),
    .b(b),
    .cin(cin),
    .clk(clk),
    .rst(rst),
    .q(q),
    .cout(cout)
);


always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    a = 0;
    b = 0;
    cin = 0;

    #10 rst = 0;

    $monitor("Time=%0t | a=%b b=%b cin=%b | sum stored in q=%b | cout=%b | clk=%b",
             $time, a, b, cin, q, cout, clk);

    for (i = 0; i < 16; i = i + 1) begin
        for (j = 0; j < 16; j = j + 1) begin
            for (k = 0; k < 2; k = k + 1) begin
                a = i;
                b = j;
                cin = k;

                #10;
            end
        end
    end

    $finish;
end

endmodule
