`timescale 1ns/1ps
module encoder_decoder_tb;
    reg [7:0] enc_in;
    wire [2:0] code_casez, code_if;
    wire valid_casez, valid_if;
    reg [2:0] dec_in;
    reg enable;
    wire [7:0] dec_out;
    reg [2:0] expected_code;
    reg expected_valid;
    reg [7:0] expected_decode;
    integer i, errors;

    priority_encoder_casez u_casez(enc_in, code_casez, valid_casez);
    priority_encoder_if    u_if(enc_in, code_if, valid_if);
    decoder3to8             u_dec(dec_in, enable, dec_out);

    initial begin
        errors = 0;
        // All 256 encoder input combinations, including multi-hot inputs.
        for (i = 0; i < 256; i = i + 1) begin
            enc_in = i;
            #1;
            expected_valid = (i != 0);
            expected_code = 0;
            if      (enc_in[7]) expected_code = 7;
            else if (enc_in[6]) expected_code = 6;
            else if (enc_in[5]) expected_code = 5;
            else if (enc_in[4]) expected_code = 4;
            else if (enc_in[3]) expected_code = 3;
            else if (enc_in[2]) expected_code = 2;
            else if (enc_in[1]) expected_code = 1;
            if (valid_casez !== expected_valid || valid_if !== expected_valid ||
                code_casez !== expected_code || code_if !== expected_code) begin
                $display("ENC FAIL in=%b casez=%b/%b if=%b/%b expected=%b/%b",
                         enc_in, valid_casez, code_casez, valid_if, code_if,
                         expected_valid, expected_code);
                errors = errors + 1;
            end
            if (code_casez !== code_if || valid_casez !== valid_if)
                errors = errors + 1;
        end

        // All 8 decoder addresses, with enable both low and high.
        for (i = 0; i < 16; i = i + 1) begin
            dec_in = i % 8;
            enable = (i >= 8);
            expected_decode = 0;
            if (enable) expected_decode[dec_in] = 1'b1;
            #1;
            if (dec_out !== expected_decode) begin
                $display("DEC FAIL enable=%b in=%d out=%b expected=%b",
                         enable, dec_in, dec_out, expected_decode);
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("ACTIVITY 1.6 PASS: 256 encoder inputs + 16 decoder cases; casez and if-else identical");
        else
            $display("ACTIVITY 1.6 FAIL: %0d mismatches", errors);
        $finish;
    end
endmodule
