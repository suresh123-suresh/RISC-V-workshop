
`timescale 1ns/1ps

module atm_fsm_tb;

    reg clk, rst;
    reg [3:0] pin;
    reg [1:0] option;
    reg [7:0] amount;

    wire [7:0] balance;
    wire [7:0] cash;
    wire valid;
    wire insufficient;
    wire [2:0] state;

    atm_fsm uut (
        .clk(clk),
        .rst(rst),
        .pin(pin),
        .option(option),
        .amount(amount),
        .balance(balance),
        .cash(cash),
        .valid(valid),
        .insufficient(insufficient),
        .state(state)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        pin = 0;
        option = 0;
        amount = 0;

        #10 rst = 0;

        // Test 1: Correct PIN - Balance inquiry
        pin = 4'b1010;
        option = 2'b00;
        amount = 0;
        #30;

        // Test 2: Withdraw 30
        pin = 4'b1010;
        option = 2'b01;
        amount = 30;
        #40;

        // Test 3: Deposit 50
        pin = 4'b1010;
        option = 2'b10;
        amount = 50;
        #40;

        // Test 4: Insufficient balance
        pin = 4'b1010;
        option = 2'b01;
        amount = 200;
        #40;

        // Test 5: Wrong PIN
        pin = 4'b1111;
        option = 2'b00;
        amount = 0;
        #40;

        $finish;
    end

    initial begin
        $monitor("Time=%0t | PIN=%b | Option=%b | Amount=%d | State=%b | Valid=%b | Balance=%d | Cash=%d | Insufficient=%b",
                 $time, pin, option, amount, state, valid, balance, cash, insufficient);
    end

endmodule
