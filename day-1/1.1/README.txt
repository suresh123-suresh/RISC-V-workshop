# Day 1 - Activity 1.1: Parameterized ALU

Files:
- `alu.v` - synthesizable parameterized ALU design.
- `alu_tb.v` - self-checking testbench with 25 directed test vectors.

## Operation encoding
| alu_op | Operation |
|---|---|
| 000 | ADD |
| 001 | SUB |
| 010 | AND |
| 011 | OR |
| 100 | XOR |
| 101 | signed SLT |
| 110 | logical shift left |
| 111 | logical shift right |

## Flags
- `zero`: result is zero.
- `negative`: most-significant result bit is 1.
- `carry`: ADD carry-out; SUB is 1 when no unsigned borrow; shifts report the last bit shifted out.
- `overflow`: signed overflow for ADD/SUB; 0 for other operations.

## ModelSim / QuestaSim
In the folder containing both files, run:

```tcl
vlib work
vlog alu.v alu_tb.v
vsim -voptargs=+acc work.alu_tb
add wave *
run -all
```

The testbench prints PASS/FAIL for each vector and a final summary. The waveform is supplementary; PASS/FAIL output is the verification result.
