
`timescale 1ns/1ps

module elevator (
    input [2:0] a,          
    input clk,
    input rst,

    output reg [2:0] q,     
    output reg up,
    output reg down,
    output reg [2:0] reached
);

always @(posedge clk or posedge rst)
begin
    if (rst) begin
        q       <= 3'b000;
        up      <= 1'b0;
        down    <= 1'b0;
        reached <= 3'b000;
    end

    else begin
        
        up      <= 1'b0;
        down    <= 1'b0;
        reached <= 3'b000;

        
        if (q < a) begin
            q  <= q + 1'b1;
            up <= 1'b1;
        end

        
        else if (q > a) begin
            q    <= q - 1'b1;
            down <= 1'b1;
        end

        
        else begin
            q       <= q;
            reached <= a;
        end
    end
end

endmodule
