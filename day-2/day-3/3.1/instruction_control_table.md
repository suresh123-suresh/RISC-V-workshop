# Activity 3.1 — Instruction Encoding and Control Summary

| Instruction | Opcode | funct3 | funct7 / immediate condition | Register write | PC control |
|---|---|---|---|---|---|
| ANDI | `0010011` | `111` | signed I-immediate | Yes | PC + 4 |
| ORI | `0010011` | `110` | signed I-immediate | Yes | PC + 4 |
| XORI | `0010011` | `100` | signed I-immediate | Yes | PC + 4 |
| SLTI | `0010011` | `010` | signed comparison | Yes | PC + 4 |
| SLLI | `0010011` | `001` | funct7 = `0000000` | Yes | PC + 4 |
| SRLI | `0010011` | `101` | funct7 = `0000000` | Yes | PC + 4 |
| LUI | `0110111` | — | U-immediate shifted left 12 | Yes | PC + 4 |
| JAL | `1101111` | — | J-immediate | Yes (`PC + 4`) | PC + J-immediate |

## Key behavior
- I-type logical operations use a sign-extended 12-bit immediate, as specified by RV32I.
- SLTI compares both operands as signed 32-bit values.
- SLLI and SRLI use the low five bits of the instruction as the shift amount.
- LUI writes the 20-bit immediate into bits `[31:12]` and clears bits `[11:0]`.
- JAL writes the address of the following instruction (`if_id_pc + 4`) to `rd`, then redirects the PC to `if_id_pc + imm_j`.
- x0 remains hardwired to zero.
