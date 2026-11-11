# Day 2 – Activity 2.2: Vending Machine Controller

## Workbook requirement
- Accept Rs.5 and Rs.10 coins.
- Item price is Rs.15.
- Dispense the item when sufficient payment is received.
- Return change when overpaid.
- A cancel input refunds the inserted credit.

## Interface assumptions used
- `coin5` and `coin10` are one-clock-cycle pulses.
- The two coin inputs must not be asserted together.
- `cancel` takes priority over coin acceptance in a cycle.
- `dispense` is a one-cycle pulse.
- `change` and `refund` are one-cycle amount outputs in rupees.
- For Rs.20 payment, the machine dispenses and returns Rs.5 change.
- Cancel in IDLE returns Rs.0.

## FSM state diagram

```text
                 coin5
          +-----------------> CREDIT5
          |                      |
          |                      | coin5
        IDLE                     v
          ^                   CREDIT10
          |                      |
          |                      | coin5 or coin10
          |                      v
          +------ vend -------- IDLE

IDLE --coin10--> CREDIT10
CREDIT5 --coin10--> vend, return to IDLE
CREDIT5 --cancel--> refund Rs.5, return to IDLE
CREDIT10 --cancel--> refund Rs.10, return to IDLE
```

The transitions that reach Rs.15 or Rs.20 vend immediately. `CREDIT10 + coin10` returns Rs.5 change.

## Files
- `vending.v` – synthesizable FSM controller.
- `vending_tb.v` – directed self-checking testbench covering acceptance, exact payment, overpayment, cancellation and idle behavior.
- `run.do` – ModelSim / QuestaSim script.

## Run in ModelSim / QuestaSim

```tcl
do run.do
```

Expected successful summary:
```text
ACTIVITY 2.2 PASS: all directed vending transitions verified
```

This is the expected testbench message, not a claim that the simulator has already been run. Capture your own waveform screenshot. Useful signals: `coin5`, `coin10`, `cancel`, internal `state`, `dispense`, `change`, and `refund`.

## Testbench scenarios
1. Rs.5 then Rs.5 then Rs.5: exact Rs.15 payment.
2. Rs.10 then Rs.5: exact Rs.15 payment.
3. Rs.10 then Rs.10: vend and Rs.5 change.
4. Cancel after Rs.5: refund Rs.5.
5. Cancel after Rs.10: refund Rs.10.
6. Cancel while idle: refund zero.
7. Confirm transaction outputs clear on the following cycle.
