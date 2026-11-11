`timescale 1ns/1ps

module riscv_5stage (
    input wire clk,
    input wire reset
);
    reg [31:0] pc;
    reg [31:0] instruction_mem [0:63];
    reg [31:0] data_mem [0:63];
    reg [31:0] registers [0:31];
    integer i;

    // IF
    wire [31:0] fetched_instruction = instruction_mem[pc[7:2]];
    reg [31:0] IF_ID_instruction, IF_ID_pc;

    // Decode
    wire [6:0] opcode = IF_ID_instruction[6:0];
    wire [4:0] rd = IF_ID_instruction[11:7];
    wire [2:0] funct3 = IF_ID_instruction[14:12];
    wire [4:0] rs1 = IF_ID_instruction[19:15];
    wire [4:0] rs2 = IF_ID_instruction[24:20];
    wire [6:0] funct7 = IF_ID_instruction[31:25];

    wire [31:0] read_data1 = (rs1 == 0) ? 32'd0 : registers[rs1];
    wire [31:0] read_data2 = (rs2 == 0) ? 32'd0 : registers[rs2];

    wire [31:0] imm_i = {{20{IF_ID_instruction[31]}}, IF_ID_instruction[31:20]};
    wire [31:0] imm_s = {{20{IF_ID_instruction[31]}}, IF_ID_instruction[31:25], IF_ID_instruction[11:7]};
    wire [31:0] imm_b = {{19{IF_ID_instruction[31]}}, IF_ID_instruction[31],
                         IF_ID_instruction[7], IF_ID_instruction[30:25],
                         IF_ID_instruction[11:8], 1'b0};
    wire [31:0] imm_j = {{11{IF_ID_instruction[31]}}, IF_ID_instruction[31],
                         IF_ID_instruction[19:12], IF_ID_instruction[20],
                         IF_ID_instruction[30:21], 1'b0};

    reg ID_reg_write, ID_mem_read, ID_mem_write, ID_alu_src;
    reg ID_branch, ID_jump;
    reg [1:0] ID_wb_sel;
    reg [3:0] ID_alu_control;

    always @(*) begin
        ID_reg_write = 0;
        ID_mem_read = 0;
        ID_mem_write = 0;
        ID_alu_src = 0;
        ID_branch = 0;
        ID_jump = 0;
        ID_wb_sel = 2'b00;
        ID_alu_control = 4'b0000;
        case (opcode)
            7'b0110011: begin
                ID_reg_write = 1;
                case (funct3)
                    3'b000: ID_alu_control = (funct7 == 7'b0100000) ? 4'b0001 : 4'b0000;
                    3'b111: ID_alu_control = 4'b0010;
                    3'b110: ID_alu_control = 4'b0011;
                    3'b100: ID_alu_control = 4'b0100;
                    3'b010: ID_alu_control = 4'b0101;
                    default: ID_reg_write = 0;
                endcase
            end
            7'b0010011: begin
                ID_reg_write = 1;
                ID_alu_src = 1;
                ID_alu_control = 4'b0000;
            end
            7'b0000011: begin
                if (funct3 == 3'b010) begin
                    ID_reg_write = 1;
                    ID_mem_read = 1;
                    ID_alu_src = 1;
                    ID_wb_sel = 2'b01;
                end
            end
            7'b0100011: begin
                if (funct3 == 3'b010) begin
                    ID_mem_write = 1;
                    ID_alu_src = 1;
                end
            end
            7'b1100011: begin
                if (funct3 == 3'b000) begin
                    ID_branch = 1; // BEQ
                    ID_alu_control = 4'b0001;
                end
            end
            7'b1101111: begin // JAL
                ID_jump = 1;
                ID_reg_write = 1;
                ID_wb_sel = 2'b10; // PC + 4
            end
            default: begin end
        endcase
    end

    // ID/EX pipeline register
    reg [31:0] ID_EX_pc, ID_EX_read_data1, ID_EX_read_data2, ID_EX_imm;
    reg [4:0] ID_EX_rd, ID_EX_rs1, ID_EX_rs2;
    reg ID_EX_reg_write, ID_EX_mem_read, ID_EX_mem_write;
    reg ID_EX_alu_src, ID_EX_branch, ID_EX_jump;
    reg [1:0] ID_EX_wb_sel;
    reg [3:0] ID_EX_alu_control;

    // EX forwarding
    reg [1:0] forward_a, forward_b;
    reg [31:0] forwarded_a, forwarded_b, alu_input_b, alu_result;
    reg zero;

    always @(*) begin
        forward_a = 0;
        forward_b = 0;
        if (EX_MEM_reg_write && !EX_MEM_mem_read && EX_MEM_rd != 0 &&
            EX_MEM_rd == ID_EX_rs1)
            forward_a = 2'b10;
        else if (MEM_WB_reg_write && MEM_WB_rd != 0 && MEM_WB_rd == ID_EX_rs1)
            forward_a = 2'b01;

        if (EX_MEM_reg_write && !EX_MEM_mem_read && EX_MEM_rd != 0 &&
            EX_MEM_rd == ID_EX_rs2)
            forward_b = 2'b10;
        else if (MEM_WB_reg_write && MEM_WB_rd != 0 && MEM_WB_rd == ID_EX_rs2)
            forward_b = 2'b01;
    end

    always @(*) begin
        case (forward_a)
            2'b01: forwarded_a = MEM_WB_data;
            2'b10: forwarded_a = EX_MEM_alu_result;
            default: forwarded_a = ID_EX_read_data1;
        endcase
        case (forward_b)
            2'b01: forwarded_b = MEM_WB_data;
            2'b10: forwarded_b = EX_MEM_alu_result;
            default: forwarded_b = ID_EX_read_data2;
        endcase
    end

    always @(*) begin
        alu_input_b = ID_EX_alu_src ? ID_EX_imm : forwarded_b;
        alu_result = 0;
        case (ID_EX_alu_control)
            4'b0000: alu_result = forwarded_a + alu_input_b;
            4'b0001: alu_result = forwarded_a - alu_input_b;
            4'b0010: alu_result = forwarded_a & alu_input_b;
            4'b0011: alu_result = forwarded_a | alu_input_b;
            4'b0100: alu_result = forwarded_a ^ alu_input_b;
            4'b0101: alu_result = ($signed(forwarded_a) < $signed(alu_input_b)) ? 1 : 0;
            default: alu_result = 0;
        endcase
        zero = (forwarded_a == forwarded_b);
    end

    reg [31:0] EX_MEM_alu_result, EX_MEM_write_data, EX_MEM_link_data;
    reg [4:0] EX_MEM_rd;
    reg EX_MEM_reg_write, EX_MEM_mem_read, EX_MEM_mem_write;
    reg [1:0] EX_MEM_wb_sel;

    reg [31:0] MEM_WB_data;
    reg [4:0] MEM_WB_rd;
    reg MEM_WB_reg_write;

    wire [31:0] memory_read_data = data_mem[EX_MEM_alu_result[7:2]];
    wire branch_taken = (ID_EX_branch && zero) || ID_EX_jump;
    wire [31:0] branch_target = ID_EX_pc + ID_EX_imm;

    reg uses_rs1, uses_rs2;
    always @(*) begin
        uses_rs1 = 0;
        uses_rs2 = 0;
        case (opcode)
            7'b0110011: begin uses_rs1=1; uses_rs2=1; end
            7'b0010011, 7'b0000011: uses_rs1=1;
            7'b0100011, 7'b1100011: begin uses_rs1=1; uses_rs2=1; end
            default: begin end
        endcase
    end
    wire stall = ID_EX_mem_read && (ID_EX_rd != 0) &&
                 ((uses_rs1 && ID_EX_rd == rs1) || (uses_rs2 && ID_EX_rd == rs2));

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 0;
            IF_ID_instruction <= 32'h00000013;
            IF_ID_pc <= 0;
            ID_EX_pc <= 0; ID_EX_read_data1 <= 0; ID_EX_read_data2 <= 0; ID_EX_imm <= 0;
            ID_EX_rd <= 0; ID_EX_rs1 <= 0; ID_EX_rs2 <= 0;
            ID_EX_reg_write <= 0; ID_EX_mem_read <= 0; ID_EX_mem_write <= 0;
            ID_EX_alu_src <= 0; ID_EX_branch <= 0; ID_EX_jump <= 0;
            ID_EX_wb_sel <= 0; ID_EX_alu_control <= 0;
            EX_MEM_alu_result <= 0; EX_MEM_write_data <= 0; EX_MEM_link_data <= 0;
            EX_MEM_rd <= 0; EX_MEM_reg_write <= 0; EX_MEM_mem_read <= 0;
            EX_MEM_mem_write <= 0; EX_MEM_wb_sel <= 0;
            MEM_WB_data <= 0; MEM_WB_rd <= 0; MEM_WB_reg_write <= 0;
            for (i=0; i<32; i=i+1) registers[i] <= 0;
        end else begin
            registers[0] <= 0;
            if (MEM_WB_reg_write && MEM_WB_rd != 0)
                registers[MEM_WB_rd] <= MEM_WB_data;

            if (EX_MEM_mem_write)
                data_mem[EX_MEM_alu_result[7:2]] <= EX_MEM_write_data;

            MEM_WB_rd <= EX_MEM_rd;
            MEM_WB_reg_write <= EX_MEM_reg_write;
            case (EX_MEM_wb_sel)
                2'b01: MEM_WB_data <= memory_read_data;
                2'b10: MEM_WB_data <= EX_MEM_link_data;
                default: MEM_WB_data <= EX_MEM_alu_result;
            endcase

            EX_MEM_alu_result <= alu_result;
            EX_MEM_write_data <= forwarded_b;
            EX_MEM_link_data <= ID_EX_pc + 32'd4;
            EX_MEM_rd <= ID_EX_rd;
            EX_MEM_reg_write <= ID_EX_reg_write;
            EX_MEM_mem_read <= ID_EX_mem_read;
            EX_MEM_mem_write <= ID_EX_mem_write;
            EX_MEM_wb_sel <= ID_EX_wb_sel;

            if (branch_taken) begin
                // Branch/jump resolves in EX: flush both younger instructions.
                pc <= branch_target;
                IF_ID_instruction <= 32'h00000013;
                IF_ID_pc <= 0;
                ID_EX_reg_write <= 0;
                ID_EX_mem_read <= 0;
                ID_EX_mem_write <= 0;
                ID_EX_branch <= 0;
                ID_EX_jump <= 0;
            end else if (stall) begin
                // Hold PC and IF/ID; inject a bubble into ID/EX.
                ID_EX_reg_write <= 0;
                ID_EX_mem_read <= 0;
                ID_EX_mem_write <= 0;
                ID_EX_branch <= 0;
                ID_EX_jump <= 0;
            end else begin
                IF_ID_instruction <= fetched_instruction;
                IF_ID_pc <= pc;
                pc <= pc + 4;

                ID_EX_pc <= IF_ID_pc;
                ID_EX_read_data1 <= read_data1;
                ID_EX_read_data2 <= read_data2;
                ID_EX_rd <= rd;
                ID_EX_rs1 <= rs1;
                ID_EX_rs2 <= rs2;
                case (opcode)
                    7'b0010011, 7'b0000011: ID_EX_imm <= imm_i;
                    7'b0100011: ID_EX_imm <= imm_s;
                    7'b1100011: ID_EX_imm <= imm_b;
                    7'b1101111: ID_EX_imm <= imm_j;
                    default: ID_EX_imm <= 0;
                endcase
                ID_EX_reg_write <= ID_reg_write;
                ID_EX_mem_read <= ID_mem_read;
                ID_EX_mem_write <= ID_mem_write;
                ID_EX_alu_src <= ID_alu_src;
                ID_EX_branch <= ID_branch;
                ID_EX_jump <= ID_jump;
                ID_EX_wb_sel <= ID_wb_sel;
                ID_EX_alu_control <= ID_alu_control;
            end
        end
    end
endmodule
