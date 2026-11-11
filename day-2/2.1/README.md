# Day 2 – Activity 2.1: Sequence Detector (1011)

## Requirement from the workbook
Detect the serial pattern `1011`, allow overlapping matches, and implement it twice:
- Moore FSM (`seq_moore.v`)
- Mealy FSM (`seq_mealy.v`)

The testbench runs three serial input streams and compares both implementations against a sliding 4-bit reference check.

## State behavior
- Moore output is asserted in the `S1011` state.
- Mealy output is asserted on the transition from `S101` when the current input bit is `1`.
- Overlap is preserved: after detecting `1011`, the trailing `1` is retained as a possible prefix.

## ModelSim / QuestaSim
Open Transcript in this folder and run:

```tcl
do run.do
```

Expected successful summary:
```text
ACTIVITY 2.1 PASS: Moore and Mealy detectors matched reference for all streams
```

This is the testbench's expected PASS message, not a claim that simulation has already been run. Save your own waveform screenshot after simulation. Useful signals: `serial_in`, `moore_detected`, `mealy_detected`, and each FSM's `state`.

## Waveform timing note
A Moore output is associated with a state; a Mealy output is associated with a state/input combination. In this implementation, both outputs are checked after each active clock edge so the testbench compares the detection cycle consistently.
