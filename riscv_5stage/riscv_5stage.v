
`timescale 1ns/1ps

module riscv_5stage (
    input wire clk,
    input wire reset
);

    //================================================
    // INSTRUCTION MEMORY, DATA MEMORY, REGISTER FILE
    //================================================

    reg [31:0] pc;

    reg [31:0] instruction_mem [0:63];
    reg [31:0] data_mem [0:63];
    reg [31:0] registers [0:31];

    integer i;

    //================================================
    // STAGE 1: FETCH (IF)
    //================================================

    wire [31:0] fetched_instruction;

    assign fetched_instruction = instruction_mem[pc[7:2]];

    // IF/ID pipeline registers
    reg [31:0] IF_ID_instruction;
    reg [31:0] IF_ID_pc;

    //================================================
    // STAGE 2: DECODE (ID)
    //================================================

    wire [6:0] opcode;
    wire [4:0] rd;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;

    assign opcode = IF_ID_instruction[6:0];
    assign rd     = IF_ID_instruction[11:7];
    assign funct3 = IF_ID_instruction[14:12];
    assign rs1    = IF_ID_instruction[19:15];
    assign rs2    = IF_ID_instruction[24:20];
    assign funct7 = IF_ID_instruction[31:25];

    wire [31:0] read_data1;
    wire [31:0] read_data2;

    assign read_data1 = (rs1 == 0) ? 32'd0 : registers[rs1];
    assign read_data2 = (rs2 == 0) ? 32'd0 : registers[rs2];

    // Immediate generation
    wire [31:0] imm_i;
    wire [31:0] imm_s;
    wire [31:0] imm_b;

    assign imm_i = {{20{IF_ID_instruction[31]}},
                    IF_ID_instruction[31:20]};

    assign imm_s = {{20{IF_ID_instruction[31]}},
                    IF_ID_instruction[31:25],
                    IF_ID_instruction[11:7]};

    assign imm_b = {{19{IF_ID_instruction[31]}},
                    IF_ID_instruction[31],
                    IF_ID_instruction[7],
                    IF_ID_instruction[30:25],
                    IF_ID_instruction[11:8],
                    1'b0};

    // Control signals
    reg ID_reg_write;
    reg ID_mem_read;
    reg ID_mem_write;
    reg ID_alu_src;
    reg [1:0] ID_wb_sel;
    reg [3:0] ID_alu_control;
    reg ID_branch;

    // ALU control encoding
    // 0000 = ADD
    // 0001 = SUB
    // 0010 = AND
    // 0011 = OR
    // 0100 = XOR
    // 0101 = SLT

    always @(*) begin

        ID_reg_write   = 1'b0;
        ID_mem_read    = 1'b0;
        ID_mem_write   = 1'b0;
        ID_alu_src     = 1'b0;
        ID_wb_sel      = 2'b00;
        ID_alu_control = 4'b0000;
        ID_branch      = 1'b0;

        case (opcode)

            // R-type instructions
            7'b0110011: begin
                ID_reg_write = 1'b1;
                ID_wb_sel = 2'b00;

                case (funct3)

                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            ID_alu_control = 4'b0001; // SUB
                        else
                            ID_alu_control = 4'b0000; // ADD
                    end

                    3'b111: ID_alu_control = 4'b0010; // AND
                    3'b110: ID_alu_control = 4'b0011; // OR
                    3'b100: ID_alu_control = 4'b0100; // XOR
                    3'b010: ID_alu_control = 4'b0101; // SLT

                    default: begin
                        ID_reg_write = 1'b0;
                    end

                endcase
            end

            // ADDI
            7'b0010011: begin
                ID_reg_write = 1'b1;
                ID_alu_src = 1'b1;
                ID_wb_sel = 2'b00;
                ID_alu_control = 4'b0000;
            end

            // LW
            7'b0000011: begin
                ID_reg_write = 1'b1;
                ID_mem_read = 1'b1;
                ID_alu_src = 1'b1;
                ID_wb_sel = 2'b01;
                ID_alu_control = 4'b0000;
            end

            // SW
            7'b0100011: begin
                ID_mem_write = 1'b1;
                ID_alu_src = 1'b1;
                ID_alu_control = 4'b0000;
            end

            // BEQ
            7'b1100011: begin
                ID_branch = 1'b1;
                ID_alu_control = 4'b0001;
            end

            default: begin
                // NOP
            end

        endcase
    end

    //================================================
    // ID/EX PIPELINE REGISTERS
    //================================================

    reg [31:0] ID_EX_pc;
    reg [31:0] ID_EX_read_data1;
    reg [31:0] ID_EX_read_data2;
    reg [31:0] ID_EX_imm;

    reg [4:0] ID_EX_rd;
    reg [4:0] ID_EX_rs1;
    reg [4:0] ID_EX_rs2;

    reg [2:0] ID_EX_funct3;
    reg [6:0] ID_EX_funct7;
    reg [6:0] ID_EX_opcode;

    reg ID_EX_reg_write;
    reg ID_EX_mem_read;
    reg ID_EX_mem_write;
    reg ID_EX_alu_src;
    reg [1:0] ID_EX_wb_sel;
    reg [3:0] ID_EX_alu_control;
    reg ID_EX_branch;

    //================================================
    // STAGE 3: EXECUTE (EX)
    //================================================

    // Forwarding control
    reg [1:0] forward_a;
    reg [1:0] forward_b;

    reg [31:0] forwarded_a;
    reg [31:0] forwarded_b;
    reg [31:0] alu_input_b;

    // EX/MEM pipeline register values
    reg [31:0] EX_MEM_alu_result;
    reg [31:0] EX_MEM_write_data;
    reg [4:0] EX_MEM_rd;
    reg EX_MEM_reg_write;
    reg EX_MEM_mem_read;
    reg EX_MEM_mem_write;
    reg [1:0] EX_MEM_wb_sel;

    // MEM/WB pipeline register values
    reg [31:0] MEM_WB_data;
    reg [4:0] MEM_WB_rd;
    reg MEM_WB_reg_write;

    reg [31:0] wb_data;

    // Forwarding from EX/MEM and MEM/WB
    always @(*) begin

        forward_a = 2'b00;
        forward_b = 2'b00;

        if (EX_MEM_reg_write && (EX_MEM_rd != 0) &&
            (EX_MEM_rd == ID_EX_rs1))
            forward_a = 2'b10;

        else if (MEM_WB_reg_write && (MEM_WB_rd != 0) &&
                 (MEM_WB_rd == ID_EX_rs1))
            forward_a = 2'b01;


        if (EX_MEM_reg_write && (EX_MEM_rd != 0) &&
            (EX_MEM_rd == ID_EX_rs2))
            forward_b = 2'b10;

        else if (MEM_WB_reg_write && (MEM_WB_rd != 0) &&
                 (MEM_WB_rd == ID_EX_rs2))
            forward_b = 2'b01;

    end

    // Select forwarded operands
    always @(*) begin

        case (forward_a)
            2'b00: forwarded_a = ID_EX_read_data1;
            2'b01: forwarded_a = wb_data;
            2'b10: forwarded_a = EX_MEM_alu_result;
            default: forwarded_a = ID_EX_read_data1;
        endcase

        case (forward_b)
            2'b00: forwarded_b = ID_EX_read_data2;
            2'b01: forwarded_b = wb_data;
            2'b10: forwarded_b = EX_MEM_alu_result;
            default: forwarded_b = ID_EX_read_data2;
        endcase

    end

    // ALU second operand selection
    always @(*) begin
        if (ID_EX_alu_src)
            alu_input_b = ID_EX_imm;
        else
            alu_input_b = forwarded_b;
    end

    // ALU
    reg [31:0] alu_result;
    reg zero;

    always @(*) begin

        alu_result = 32'd0;
        zero = 1'b0;

        case (ID_EX_alu_control)

            4'b0000: alu_result = forwarded_a + alu_input_b; // ADD
            4'b0001: alu_result = forwarded_a - alu_input_b; // SUB
            4'b0010: alu_result = forwarded_a & alu_input_b; // AND
            4'b0011: alu_result = forwarded_a | alu_input_b; // OR
            4'b0100: alu_result = forwarded_a ^ alu_input_b; // XOR

            4'b0101: begin
                if ($signed(forwarded_a) < $signed(alu_input_b))
                    alu_result = 32'd1;
                else
                    alu_result = 32'd0; // SLT
            end

            default: alu_result = 32'd0;

        endcase

        if (forwarded_a == forwarded_b)
            zero = 1'b1;

    end

    // Branch calculation
    wire branch_taken;
    wire [31:0] branch_target;

    assign branch_taken = ID_EX_branch && zero;
    assign branch_target = ID_EX_pc + ID_EX_imm;

    //================================================
    // STAGE 4: MEMORY ACCESS (MEM)
    //================================================

    wire [31:0] memory_read_data;

    assign memory_read_data = data_mem[EX_MEM_alu_result[7:2]];

    //================================================
    // STAGE 5: WRITEBACK (WB)
    //================================================

    always @(*) begin

        case (EX_MEM_wb_sel)
            2'b00: wb_data = MEM_WB_data; // ALU result
            2'b01: wb_data = MEM_WB_data; // Load data (from MEM/WB)
            default: wb_data = MEM_WB_data;
        endcase

    end

    //================================================
    // LOAD-USE HAZARD DETECTION
    //================================================

    wire stall;

    assign stall = ID_EX_mem_read &&
                   (ID_EX_rd != 0) &&
                   ((ID_EX_rd == rs1) || (ID_EX_rd == rs2));

    //================================================
    // PIPELINE SEQUENTIAL LOGIC
    //================================================

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            pc <= 32'd0;

            IF_ID_instruction <= 32'h00000013; // NOP
            IF_ID_pc <= 32'd0;

            ID_EX_pc <= 32'd0;
            ID_EX_read_data1 <= 32'd0;
            ID_EX_read_data2 <= 32'd0;
            ID_EX_imm <= 32'd0;

            ID_EX_rd <= 5'd0;
            ID_EX_rs1 <= 5'd0;
            ID_EX_rs2 <= 5'd0;

            ID_EX_funct3 <= 3'd0;
            ID_EX_funct7 <= 7'd0;
            ID_EX_opcode <= 7'd0;

            ID_EX_reg_write <= 1'b0;
            ID_EX_mem_read <= 1'b0;
            ID_EX_mem_write <= 1'b0;
            ID_EX_alu_src <= 1'b0;
            ID_EX_wb_sel <= 2'b00;
            ID_EX_alu_control <= 4'b0000;
            ID_EX_branch <= 1'b0;

            EX_MEM_alu_result <= 32'd0;
            EX_MEM_write_data <= 32'd0;
            EX_MEM_rd <= 5'd0;
            EX_MEM_reg_write <= 1'b0;
            EX_MEM_mem_read <= 1'b0;
            EX_MEM_mem_write <= 1'b0;
            EX_MEM_wb_sel <= 2'b00;

            MEM_WB_data <= 32'd0;
            MEM_WB_rd <= 5'd0;
            MEM_WB_reg_write <= 1'b0;

            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;

        end

        else begin

            registers[0] <= 32'd0;

            //============================================
            // WRITEBACK
            //============================================

            if (MEM_WB_reg_write && (MEM_WB_rd != 0))
                registers[MEM_WB_rd] <= MEM_WB_data;

            //============================================
            // MEMORY ACCESS
            //============================================

            if (EX_MEM_mem_write)
                data_mem[EX_MEM_alu_result[7:2]] <= EX_MEM_write_data;

            MEM_WB_rd <= EX_MEM_rd;
            MEM_WB_reg_write <= EX_MEM_reg_write;

            if (EX_MEM_wb_sel == 2'b01)
                MEM_WB_data <= memory_read_data;
            else
                MEM_WB_data <= EX_MEM_alu_result;

            //============================================
            // EXECUTE -> EX/MEM
            //============================================

            EX_MEM_alu_result <= alu_result;
            EX_MEM_write_data <= forwarded_b;
            EX_MEM_rd <= ID_EX_rd;
            EX_MEM_reg_write <= ID_EX_reg_write;
            EX_MEM_mem_read <= ID_EX_mem_read;
            EX_MEM_mem_write <= ID_EX_mem_write;
            EX_MEM_wb_sel <= ID_EX_wb_sel;

            //============================================
            // BRANCH HANDLING
            //============================================

            if (branch_taken) begin

                pc <= branch_target;

                // Flush instructions from IF and ID
                IF_ID_instruction <= 32'h00000013;

                ID_EX_reg_write <= 1'b0;
                ID_EX_mem_read <= 1'b0;
                ID_EX_mem_write <= 1'b0;
                ID_EX_branch <= 1'b0;

            end

            //============================================
            // HAZARD STALL
            //============================================

            else if (stall) begin

                // Keep PC and IF/ID unchanged
                // Insert a bubble into ID/EX

                ID_EX_reg_write <= 1'b0;
                ID_EX_mem_read <= 1'b0;
                ID_EX_mem_write <= 1'b0;
                ID_EX_branch <= 1'b0;

            end

            //============================================
            // FETCH AND DECODE
            //============================================

            else begin

                // FETCH
                IF_ID_instruction <= fetched_instruction;
                IF_ID_pc <= pc;
                pc <= pc + 32'd4;

                // DECODE -> ID/EX
                ID_EX_pc <= IF_ID_pc;

                ID_EX_read_data1 <= read_data1;
                ID_EX_read_data2 <= read_data2;

                ID_EX_rd <= rd;
                ID_EX_rs1 <= rs1;
                ID_EX_rs2 <= rs2;

                ID_EX_funct3 <= funct3;
                ID_EX_funct7 <= funct7;
                ID_EX_opcode <= opcode;

                // Immediate selection
                case (opcode)

                    7'b0010011,
                    7'b0000011:
                        ID_EX_imm <= imm_i;

                    7'b0100011:
                        ID_EX_imm <= imm_s;

                    7'b1100011:
                        ID_EX_imm <= imm_b;

                    default:
                        ID_EX_imm <= 32'd0;

                endcase

                ID_EX_reg_write <= ID_reg_write;
                ID_EX_mem_read <= ID_mem_read;
                ID_EX_mem_write <= ID_mem_write;
                ID_EX_alu_src <= ID_alu_src;
                ID_EX_wb_sel <= ID_wb_sel;
                ID_EX_alu_control <= ID_alu_control;
                ID_EX_branch <= ID_branch;

            end

        end

    end

endmodule
