# Advanced 8-Player Buzzer System

A scalable, multi-player quiz buzzer system in Verilog, supporting 8 players
with priority-based lockout, live score tracking, 7-segment display output,
and buzzer audio feedback.

## What it does
- **8-player support** — any of 8 buzzer inputs can trigger a round win
- **Priority-encoded lockout** — if multiple players buzz simultaneously, the
  lowest-indexed player wins, and all other inputs are locked out for that
  round (eliminates race conditions between concurrent hardware inputs)
- **Live score tracking** — maintains a running score per player across
  rounds
- **7-segment display** — multiplexed display cycles through round status,
  winning player ID, and that player's current score
- **Buzzer audio feedback** — distinct tones for a round win vs. a timeout
- **Configurable round timer** — optional countdown per round, with a
  timeout state if no one buzzes in time

## Architecture
Implemented as a finite state machine with five states:

| State     | Behaviour                                                |
| --------- | --------------------------------------------------------- |
| IDLE      | Waiting for a new round to start                          |
| WAITING   | Round active, listening for buzzer input and/or timer     |
| LOCKED    | A winner has been detected; lockout engaged, sound plays  |
| SCORING   | Winner's score incremented, then returns to IDLE          |
| TIME_OUT  | No winner before the timer expired; timeout tone plays    |

Winner selection uses a priority encoder over the 8 buzzer inputs, so
simultaneous presses always resolve deterministically to the lowest-indexed
active player.

## Verification
Verified with a comprehensive testbench (`buzzer_system_tb.v`) covering:
- Single-player wins (including edge players, e.g., Player 8)
- Lockout correctness (a second press after lockout is ignored)
- Priority encoding under simultaneous multi-player presses
- Score accumulation across multiple rounds, including for the same player
  winning repeatedly
- Reset behaviour mid-round, and score reset to zero
- Edge cases: no buzzer press before timeout, rapid successive rounds,
  premature buzzer press before round start
- Buzzer sound activation and 7-segment display multiplexing

All test suites pass; the testbench prints a full pass/fail summary and
final scoreboard on completion.

## Running the testbench
\`\`\`
iverilog -o buzzer_sim buzzer_system.v buzzer_system_tb.v
vvp buzzer_sim
\`\`\`
*(adjust to match your actual simulator — Icarus Verilog assumed here)*

## Tech stack
Verilog, FPGA synthesis-target design (LUT-optimized)

## Files
- `buzzer_system.v` — main FSM and logic
- `buzzer_system_tb.v` — comprehensive testbench
