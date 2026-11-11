# Day 4 — Activity 4.1: Data Hazard Handling

## What this activity implements
- EX/MEM to EX forwarding.
- MEM/WB to EX forwarding.
- One-cycle load-use interlock.
- Holding PC and IF/ID during a load-use stall.
- Inserting a bubble into ID/EX.
- Store-data forwarding and a directed branch flush check.

## Files
- `riscv_5stage.v`: five-stage pipeline RTL.
- `tb_riscv_5stage_hazards.v`: self-checking testbench.
- `programs/hazard_test.hex`: directed hazard program.
- `run.do`: ModelSim script.

## Run
Open ModelSim in this directory and execute:
`do run.do`

Expected final line:
`DAY 4 ACTIVITY 4.1: ALL HAZARD CHECKS PASSED`

## Signals to inspect
- `stall`: should assert for the LW followed immediately by dependent ADD.
- `forward_a`, `forward_b`: `10` selects EX/MEM; `01` selects MEM/WB.
- `branch_taken` and `branch_target`: show the taken BEQ redirect.
- `IF_ID_instruction`: observe the bubble/flush behavior.

## Important verification note
The supplied five-stage RTL was reviewed and adjusted for this activity. In particular, EX/MEM forwarding is disabled for loads so an effective address is never mistaken for loaded data, and load-use detection checks only source operands actually used by the decoded instruction.

The package has not been executed in ModelSim here. Do not claim PASS until the simulator prints the expected final line. If it fails, share the Transcript and waveform; debug the first incorrect cycle rather than changing the expected values.
