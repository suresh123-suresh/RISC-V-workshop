# Activity 3.4 — Waveform Analysis (Program 1: Sum 1 to 10)

## Program under analysis

The program calculates `1 + 2 + ... + 10` and stores the result at data-memory byte address 0.

| PC (hex) | Instruction | Purpose |
|---|---|---|
| `0x00` | `addi x1,x0,10` | Initialize loop count to 10 |
| `0x04` | `addi x2,x0,0` | Clear accumulator |
| `0x08` | `addi x3,x0,1` | Initialize current number |
| `0x0C` | `add x2,x2,x3` | Add current number to sum |
| `0x10` | `addi x3,x3,1` | Increment current number |
| `0x14` | `addi x1,x1,-1` | Decrement loop count |
| `0x18` | `beq x1,x0,+8` | Exit loop when count becomes zero |
| `0x1C` | `beq x0,x0,-16` | Unconditional branch back to loop body |
| `0x20` | `sw x2,0(x0)` | Store final sum |
| `0x24` | `nop` | Padding |
| `0x28` | `jal x0,0` | Terminal self-loop used by the later testbench |

## Three waveform points to annotate

Capture these points in ModelSim. Exact timestamps depend on reset release and clock scheduling, so identify them by `if_id_pc` and instruction rather than assuming fixed times.

### Point A — ADD instruction at PC 0x0C
- `if_id_pc` identifies the ADD instruction `add x2,x2,x3`.
- `read_data1` is the previous accumulated sum and `read_data2` is the current loop number.
- `alu_result` is their sum.
- `write_data` carries the ALU result for register write-back to x2.
- After the active clock edge, x2 updates to the new accumulated sum.

### Point B — Conditional branch at PC 0x18
- `if_id_pc` identifies `beq x1,x0,+8`.
- When x1 is nonzero, `branch_taken` is 0 and execution proceeds to PC 0x1C.
- On the final iteration, x1 is zero, so `branch_taken` becomes 1.
- `branch_target` is 0x20; the CPU redirects the PC there and inserts a NOP into the instruction register to flush the wrong-path fetch.

### Point C — Store instruction at PC 0x20
- `if_id_pc` identifies `sw x2,0(x0)`.
- `alu_result` is the effective byte address 0.
- `mem_write` is asserted and `read_data2` carries the final sum 55.
- At the active clock edge, `data_mem[0]` is updated to 55.

## What to include in your submission
1. One ModelSim waveform screenshot with `pc`, `if_id_pc`, `if_id_instruction`, `alu_result`, `write_data`, `branch_taken`, `branch_target`, `reg_write`, `mem_write`, x1, x2, x3 and `data_mem[0]` visible.
2. Mark Point A (ADD), Point B (BEQ taken) and Point C (SW).
3. Add the three explanations above to your report, using your actual waveform values.
4. Confirm the Transcript prints `PASS: Program 1 stored sum 55 in data_mem[0]`.

## Important
This is the supplied two-stage CPU. The activity report describes its actual IF + combined decode/execute/memory/write-back behavior; it does not describe a single-cycle datapath.
