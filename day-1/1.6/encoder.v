`timescale 1ns/1ps
// Bit 7 has the highest priority. Both implementations must agree.
module priority_encoder_casez(
    input  wire [7:0] in,
    output reg  [2:0] code,
    output reg        valid
);
    always @* begin
        valid = 1'b1;
        casez (in)
            8'b1???????: code = 3'd7;
            8'b01??????: code = 3'd6;
            8'b001?????: code = 3'd5;
            8'b0001????: code = 3'd4;
            8'b00001???: code = 3'd3;
            8'b000001??: code = 3'd2;
            8'b0000001?: code = 3'd1;
            8'b00000001: code = 3'd0;
            default: begin code = 3'd0; valid = 1'b0; end
        endcase
    end
endmodule

module priority_encoder_if(
    input  wire [7:0] in,
    output reg  [2:0] code,
    output reg        valid
);
    always @* begin
        code = 3'd0;
        valid = 1'b1;
        if      (in[7]) code = 3'd7;
        else if (in[6]) code = 3'd6;
        else if (in[5]) code = 3'd5;
        else if (in[4]) code = 3'd4;
        else if (in[3]) code = 3'd3;
        else if (in[2]) code = 3'd2;
        else if (in[1]) code = 3'd1;
        else if (in[0]) code = 3'd0;
        else valid = 1'b0;
    end
endmodule

module decoder3to8(
    input  wire [2:0] in,
    input  wire       enable,
    output reg  [7:0] out
);
    always @* begin
        out = 8'b0;
        if (enable)
            out[in] = 1'b1;
    end
endmodule
