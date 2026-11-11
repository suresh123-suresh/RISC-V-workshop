`timescale 1ns/1ps

module adder_tb;

reg [3:0] a, b;
reg cin;

wire [3:0] sum;
wire cout;

integer i, j, k;

adder uut(a, b, cin, sum, cout);

initial
begin
    $monitor("a=%b b=%b cin=%b sum=%b cout=%b",
              a, b, cin, sum, cout);

    for(i = 0; i < 16; i = i + 1)
    begin
        for(j = 0; j < 16; j = j + 1)
        begin
            for(k = 0; k < 2; k = k + 1)
            begin
                a = i;
                b = j;
                cin = k;

                #10;
            end
        end
    end

    
end

endmodule