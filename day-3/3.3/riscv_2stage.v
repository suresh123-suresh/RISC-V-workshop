`timescale 1ns/1ps

// Two-stage educational RISC-V CPU.
// Stage 1: Instruction Fetch
// Stage 2: Decode, Execute, Memory Access and Write Back
//
// Supported instructions:
// ADD, SUB, AND, OR, ADDI, ANDI, ORI, XORI, SLTI,
// SLLI, SRLI, LUI, LW, SW, BEQ, JAL
//
// No forwarding/hazard unit is required for this two-stage structure:
// the instruction in IF/ID reads registers after the previous instruction
// has completed its write-back at the preceding active clock edge.

module riscv_2stage (
    input wire clk,
    input wire reset
);

    reg [31:0] pc;
    reg [31:0] instruction_mem [0:63];
    reg [31:0] data_mem        [0:63];
    reg [31:0] registers       [0:31];

    reg [31:0] if_id_instruction;
    reg [31:0] if_id_pc;

    wire [6:0] opcode = if_id_instruction[6:0];
    wire [4:0] rd     = if_id_instruction[11:7];
    wire [2:0] funct3 = if_id_instruction[14:12];
    wire [4:0] rs1    = if_id_instruction[19:15];
    wire [4:0] rs2    = if_id_instruction[24:20];
    wire [6:0] funct7 = if_id_instruction[31:25];

    wire [31:0] read_data1 = (rs1 == 0) ? 32'd0 : registers[rs1];
    wire [31:0] read_data2 = (rs2 == 0) ? 32'd0 : registers[rs2];

    wire [31:0] imm_i = {{20{if_id_instruction[31]}},
                          if_id_instruction[31:20]};
    wire [31:0] imm_s = {{20{if_id_instruction[31]}},
                          if_id_instruction[31:25],
                          if_id_instruction[11:7]};
    wire [31:0] imm_b = {{19{if_id_instruction[31]}},
                          if_id_instruction[31],
                          if_id_instruction[7],
                          if_id_instruction[30:25],
                          if_id_instruction[11:8],
                          1'b0};
    wire [31:0] imm_u = {if_id_instruction[31:12], 12'b0};
    wire [31:0] imm_j = {{11{if_id_instruction[31]}},
                          if_id_instruction[31],
                          if_id_instruction[19:12],
                          if_id_instruction[20],
                          if_id_instruction[30:21],
                          1'b0};

    reg [31:0] alu_result;
    reg [31:0] write_data;
    reg        reg_write;
    reg        mem_write;
    reg        branch_taken;
    reg [31:0] branch_target;

    always @(*) begin
        alu_result    = 32'd0;
        write_data    = 32'd0;
        reg_write     = 1'b0;
        mem_write     = 1'b0;
        branch_taken  = 1'b0;
        branch_target = if_id_pc + imm_b;

        case (opcode)
            7'b0110011: begin // R-type: ADD, SUB, AND, OR
                reg_write = 1'b1;
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            alu_result = read_data1 - read_data2;
                        else if (funct7 == 7'b0000000)
                            alu_result = read_data1 + read_data2;
                        else
                            reg_write = 1'b0;
                    end
                    3'b111: begin
                        if (funct7 == 7'b0000000)
                            alu_result = read_data1 & read_data2;
                        else
                            reg_write = 1'b0;
                    end
                    3'b110: begin
                        if (funct7 == 7'b0000000)
                            alu_result = read_data1 | read_data2;
                        else
                            reg_write = 1'b0;
                    end
                    default: reg_write = 1'b0;
                endcase
                write_data = alu_result;
            end

            7'b0010011: begin // I-type ALU instructions
                case (funct3)
                    3'b000: begin // ADDI
                        alu_result = read_data1 + imm_i;
                        reg_write = 1'b1;
                    end
                    3'b111: begin // ANDI
                        alu_result = read_data1 & imm_i;
                        reg_write = 1'b1;
                    end
                    3'b110: begin // ORI
                        alu_result = read_data1 | imm_i;
                        reg_write = 1'b1;
                    end
                    3'b100: begin // XORI
                        alu_result = read_data1 ^ imm_i;
                        reg_write = 1'b1;
                    end
                    3'b010: begin // SLTI: signed comparison
                        alu_result = ($signed(read_data1) < $signed(imm_i)) ? 32'd1 : 32'd0;
                        reg_write = 1'b1;
                    end
                    3'b001: begin // SLLI; upper immediate bits must be zero
                        if (funct7 == 7'b0000000) begin
                            alu_result = read_data1 << if_id_instruction[24:20];
                            reg_write = 1'b1;
                        end
                    end
                    3'b101: begin // SRLI; this activity does not add SRAI
                        if (funct7 == 7'b0000000) begin
                            alu_result = read_data1 >> if_id_instruction[24:20];
                            reg_write = 1'b1;
                        end
                    end
                    default: reg_write = 1'b0;
                endcase
                write_data = alu_result;
            end

            7'b0110111: begin // LUI
                alu_result = imm_u;
                write_data = imm_u;
                reg_write = 1'b1;
            end

            7'b0000011: begin // LW
                if (funct3 == 3'b010) begin
                    alu_result = read_data1 + imm_i;
                    reg_write = 1'b1;
                    write_data = data_mem[alu_result[7:2]];
                end
            end

            7'b0100011: begin // SW
                if (funct3 == 3'b010) begin
                    alu_result = read_data1 + imm_s;
                    mem_write = 1'b1;
                end
            end

            7'b1100011: begin // BEQ
                if (funct3 == 3'b000) begin
                    branch_taken = (read_data1 == read_data2);
                    branch_target = if_id_pc + imm_b;
                end
            end

            7'b1101111: begin // JAL
                branch_taken = 1'b1;
                branch_target = if_id_pc + imm_j;
                alu_result = if_id_pc + 32'd4;
                write_data = alu_result;
                reg_write = 1'b1;
            end

            default: begin
                // Unsupported instruction behaves as NOP.
            end
        endcase
    end

    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'd0;
            if_id_instruction <= 32'h00000013;
            if_id_pc <= 32'd0;
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;
        end else begin
            if (mem_write)
                data_mem[alu_result[7:2]] <= read_data2;

            if (reg_write && (rd != 0))
                registers[rd] <= write_data;

            registers[0] <= 32'd0;

            if (branch_taken) begin
                pc <= branch_target;
                if_id_instruction <= 32'h00000013; // Flush wrong-path fetch.
                if_id_pc <= branch_target;
            end else begin
                if_id_instruction <= instruction_mem[pc[7:2]];
                if_id_pc <= pc;
                pc <= pc + 32'd4;
            end
        end
    end

endmodule
