# Day 3 — Activity 3.1: Instruction Extensions (2-Stage CPU)

## Files
- `riscv_2stage.v`: updated two-stage CPU RTL.
- `tb_riscv_2stage.v`: self-checking testbench for the new instructions.
- `run.do`: ModelSim compile, simulation and waveform setup.
- `instruction_control_table.md`: instruction encoding and control summary.

## Added instructions
ANDI, ORI, XORI, SLTI, SLLI, SRLI, LUI and JAL.

Existing support retained: ADD, SUB, AND, OR, ADDI, LW, SW and BEQ.

## Run in ModelSim
1. Extract this folder.
2. Open ModelSim and change directory to this folder.
3. Run: `do run.do`
4. Check the Transcript for `ACTIVITY 3.1 TEST PASSED`.
5. Inspect PC, instruction, ALU result, write-back data, branch_taken and branch_target.

## Important architecture note
This is still the supplied IF + combined Decode/Execute/Memory/Write-Back two-stage CPU.
It is not a single-cycle CPU and it is not the five-stage pipeline. JAL uses the existing
flush-on-control-transfer mechanism. The testbench avoids relying on unsupported instructions.

## Verification status
The testbench is supplied but has not been executed in ModelSim here. Do not mark it PASS
until you run it and see the PASS message in your simulator.

## Known scope limits
- JALR, BNE, BLT and BGE are not added yet; those belong to Activity 3.5.
- SRAI is not added; Activity 3.1 requests SLLI and SRLI only.
- The original CPU has no exception/trap handling or instruction alignment checks.
