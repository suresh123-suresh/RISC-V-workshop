# Day 3 — Activity 3.2: Assembly Programs (2-Stage CPU)

## Programs
1. `program1.hex`: calculate 1 + 2 + ... + 10 and store 55 at data memory byte address 0.
2. `program2.hex`: store the first ten Fibonacci values (0, 1, 1, 2, 3, 5, 8, 13, 21, 34) at byte addresses 0 through 36.
3. `program3.hex`: find the maximum of eight non-negative signed 32-bit values and store it at byte address 32.

## Files
- `programs/program1.hex`, `programs/program2.hex`, `programs/program3.hex`: hand-assembled instruction memory images with assembly comments.
- `tb_riscv_day3_programs.v`: loads each program, runs the CPU and checks expected data memory values.
- `riscv_2stage.v`: Activity 3.1 extended two-stage CPU RTL.
- `run.do`: ModelSim script.

## Run
Extract the ZIP, open ModelSim in this folder, then run:
`do run.do`

Expected final line:
`DAY 3 ACTIVITY 3.2: ALL PROGRAMS PASSED`

Do not mark the activity complete until ModelSim actually prints the final PASS line.

## Addressing convention
The CPU indexes data memory using `alu_result[7:2]`. Thus byte address 0 maps to `data_mem[0]`, byte address 4 maps to `data_mem[1]`, and byte address 32 maps to `data_mem[8]`.

## Design note
The maximum-finding program uses SUB followed by signed SLTI against zero, then BEQ, so it can compare non-negative array values using the Activity 3.1 instruction set. The program is intentionally unrolled across the eight array entries; it still performs all eight comparisons but avoids requiring an additional branch instruction.
