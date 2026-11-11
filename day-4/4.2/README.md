# Day 4 — Activity 4.2: Control Hazard Handling

## Implemented
- BEQ taken branch redirection.
- BEQ not-taken sequential execution.
- JAL jump redirection and PC+4 link write-back.
- Flush of IF/ID and ID/EX younger instructions when control transfer resolves in EX.

## Files
- `riscv_5stage.v`: five-stage CPU with control-transfer flush logic and JAL support.
- `tb_riscv_5stage_control.v`: self-checking testbench.
- `programs/control_hazard_test.hex`: directed taken/not-taken branch and JAL program.
- `run.do`: ModelSim script.

## Run
From this folder in ModelSim:
`do run.do`

Expected final line:
`DAY 4 ACTIVITY 4.2: CONTROL HAZARD TESTS PASSED`

## Expected register results
- x1 = 5
- x2 = 0 (skipped by taken BEQ)
- x3 = 7
- x4 = 9 (not-taken branch falls through)
- x5 = 11 (JAL target)
- x6 = 28 (JAL return address)
- x7 = 0 (skipped by JAL)

## Waveform signals
`pc`, `IF_ID_pc`, `IF_ID_instruction`, `branch_taken`, `branch_target`,
`ID_EX_branch`, `ID_EX_jump`, `stall`, `ID_EX_pc`, `MEM_WB_data`.

## Note
The branch/jump decision is made in EX. At the redirect edge, the current
control-transfer instruction is allowed to advance toward write-back while
the two younger instructions are flushed. The package has not been run in
ModelSim here; confirm the Transcript before claiming PASS.
