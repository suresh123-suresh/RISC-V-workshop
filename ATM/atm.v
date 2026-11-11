
module atm_fsm (
    input clk,
    input rst,
    input [3:0] pin,
    input [1:0] option,
    input [7:0] amount,

    output reg [7:0] balance,
    output reg [7:0] cash,
    output reg valid,
    output reg insufficient,
    output reg [2:0] state
);

    parameter PIN = 4'b1010;

    // State encoding
    parameter IDLE       = 3'b000;
    parameter CHECK_PIN  = 3'b001;
    parameter BALANCE    = 3'b010;
    parameter WITHDRAW   = 3'b011;
    parameter DEPOSIT    = 3'b100;
    parameter ERROR      = 3'b101;

    reg [3:0] entered_pin;
    reg [1:0] operation;
    reg [7:0] transaction_amount;

    // FSM: Sequential block
    always @(posedge clk or posedge rst)
    begin
        if (rst) begin
            state              <= IDLE;
            balance            <= 8'd100;
            cash               <= 8'd0;
            valid              <= 1'b0;
            insufficient       <= 1'b0;
            entered_pin        <= 4'd0;
            operation          <= 2'd0;
            transaction_amount <= 8'd0;
        end
        else begin
            case (state)

                IDLE: begin
                    valid <= 1'b0;
                    cash <= 8'd0;
                    insufficient <= 1'b0;

                    entered_pin <= pin;
                    operation <= option;
                    transaction_amount <= amount;

                    state <= CHECK_PIN;
                end

                CHECK_PIN: begin
                    if (entered_pin == PIN) begin
                        valid <= 1'b1;

                        case (operation)
                            2'b00: state <= BALANCE;
                            2'b01: state <= WITHDRAW;
                            2'b10: state <= DEPOSIT;
                            default: state <= ERROR;
                        endcase
                    end
                    else begin
                        valid <= 1'b0;
                        state <= ERROR;
                    end
                end

                BALANCE: begin
                    state <= IDLE;
                end

                WITHDRAW: begin
                    if (transaction_amount <= balance) begin
                        balance <= balance - transaction_amount;
                        cash <= transaction_amount;
                        state <= IDLE;
                    end
                    else begin
                        insufficient <= 1'b1;
                        state <= ERROR;
                    end
                end

                DEPOSIT: begin
                    balance <= balance + transaction_amount;
                    state <= IDLE;
                end

                ERROR: begin
                    state <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule
