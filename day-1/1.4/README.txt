# Day 1 - Activity 1.4: 32 x 32 Register File

## Files
- `regfile.v`: synthesizable 32 x 32 register file RTL.
- `regfile_tb.v`: self-checking testbench with directed tests and 200 pseudo-random transactions.

## Workbook requirements (PDF page 3)
- 32 registers, each 32 bits wide.
- Two read ports.
- One write port.
- Write enable.
- x0 hardwired to zero.
- Same-cycle read/write bypass.
- Directed tests for x0 writes, bypass and back-to-back writes.
- At least 200 operations in the testbench.

## Interface
| Signal | Description |
|---|---|
| `clk` | Rising-edge write clock |
| `we` | Write enable |
| `wa` | 5-bit write address |
| `wd` | 32-bit write data |
| `ra1`, `ra2` | Two 5-bit read addresses |
| `rd1`, `rd2` | Two asynchronous 32-bit read data outputs |

## ModelSim / QuestaSim
```tcl
vlib work
vlog regfile.v regfile_tb.v
vsim -voptargs=+acc work.regfile_tb
add wave *
run -all
```

Expected final line: `OVERALL RESULT: PASS`.

## Waveform signals
Add `clk`, `we`, `wa`, `wd`, `ra1`, `ra2`, `rd1`, and `rd2`.
Inspect the x0 write attempt, same-cycle bypass, consecutive writes to the same address, and random read/write activity.

## Design note
The RTL intentionally does not initialize the register array. Real hardware register-file power-up contents are technology-dependent. The testbench initializes every nonzero register by writing it before relying on its contents. x0 is not stored and always reads as zero.
