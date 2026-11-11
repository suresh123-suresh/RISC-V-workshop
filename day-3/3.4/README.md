# Day 3 — Activity 3.4: Waveform Analysis

## Files
- `riscv_2stage.v`: CPU RTL from Activity 3.1.
- `programs/program1.hex`: sum 1 to 10 program.
- `tb_riscv_waveform.v`: runs Program 1 and checks that the stored sum is 55.
- `run.do`: ModelSim compile, simulation and waveform setup.
- `waveform_analysis.md`: signal guide and three waveform explanations.

## Run
From this folder in ModelSim:
`do run.do`

Capture a waveform showing an ADD, the taken BEQ and the final SW. Use `if_id_pc` to identify which instruction is being executed. The exact simulation times can vary with reset timing.

## Expected check
`PASS: Program 1 stored sum 55 in data_mem[0]`

The package has not been run in ModelSim here. Confirm the PASS line and inspect the actual waveform before submitting.
