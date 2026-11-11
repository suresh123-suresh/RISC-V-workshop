# Day 3 — Activity 3.3: Self-Checking CPU Testbench

## Deliverables
- `cpu_tb.v`: self-checking testbench that runs all three assembly programs.
- `riscv_2stage.v`: Activity 3.1 two-stage CPU.
- `programs/program1.hex`: sum 1 through 10.
- `programs/program2.hex`: first ten Fibonacci values.
- `programs/program3.hex`: maximum of eight array values.
- `run.do`: ModelSim compile, run and waveform commands.

## Completion detection
The CPU has no HALT output. Each program image therefore ends with `JAL x0,0`.
The testbench detects the terminal self-loop and has a cycle timeout to prevent a
simulation from hanging forever.

## Expected results
- Program 1: `data_mem[0] = 55`.
- Program 2: `data_mem[0:9] = 0,1,1,2,3,5,8,13,21,34`.
- Program 3: `data_mem[8] = 42` (byte address 32).

## Run in ModelSim
1. Extract the ZIP.
2. Set ModelSim's working directory to this folder.
3. Execute `do run.do`.
4. Confirm the Transcript ends with:
   `ACTIVITY 3.3: ALL THREE PROGRAMS PASSED`

## Important
The package is designed for the supplied two-stage CPU, not a single-cycle or five-stage CPU.
The testbench is provided but has not been executed in ModelSim here. Only mark PASS after
your own simulator run confirms the result.
