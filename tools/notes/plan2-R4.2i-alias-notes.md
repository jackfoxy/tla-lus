# R4.2i — ALIAS with a temporal PROPERTY and in simulation (2026-10-16)

Both refusals (R2.3.2) are retired. tlc2 aliases the lasso (`LiveWorker`) and
the simulated behavior (`SimulationWorker`); the port now does too.

## Measured at the pin

- Lasso, back-to-state closer (`x' = (x + 1) % 3`, `<>(x = 5)`): each prefix
  state is paired with the next; the LAST with the state the cycle returns
  to (`nx = 0` on `x = 2`, cycle to `x = 0`).
- Lasso, stuttering closer: the last state paired with itself.
- Simulation (`-simulate`): each state with the next, the last with itself
  (the safety pairing).

## Port

- `lib/check`: `+live-prefix-lines` takes `al` and `lsuc`; `+live-render`,
  `+live-report`, `+post-error-live` take `al`; the console refusal is gone.
- `lib/job`: the `%live` and `%sim` konts carry `al`; the typed `%lasso` and
  `%simulate` traces are aliased the same way (`+trace-states-to`); both
  refusals gone.

## Tests

mc `alias-lasso-back`, `alias-lasso-stutter` (pin goldens); job
`test-sim-alias`; `test-alias-refused-with-property` and
`test-alias-refused-in-simulation` retired.

## Census

braf, TokenRing, Huang now run (limited by time, R4.3). EWD840_anim and
EWD687a_anim run but DIVERGE from the pin in simulation: with seed 0 the pin
violates `AnimInv` at trace 39 (268,287 states); the port completes 100
traces without a violation. A new row (simulation draw divergence on a large
random-initial-state spec), not an ALIAS defect.

## R4.2as — the `_anim` simulation divergence (2026-10-17)

Localized with a probe (`e840probe`: `Inv3 == TLCGet("level") < 3`, seed 0,
pin vs port first behavior):

1. **A real defect, fixed:** `TLCGet("level")` was the constant 0 in
   simulation (`+sim-step` bound `[& 0 ~]`), so `AnimInv == terminationDetected
   => TLCGet("level") < 20` could never fail. Now the expanded state's
   position (initial = 1) for actions and its successor's for invariants and
   constraints (`+succ-level`). sim-diff case `level` (pin goldens, 3 seeds).
2. **Rendering, fixed:** the job's simulation report labelled every step with
   the whole Next and the first state `<Initial predicate>`; the pin names the
   generating action and labels state 1 with the Init definition
   (`<AnimInit line 11, col 3 to line 15, col 31 of module EWD840_anim>`).
   `+sim-init-label`, render with the actions/env/order (job
   `test-sim-alias` asserts both labels).
3. **What remains is an approved difference:** the first behaviors still
   differ because `Color == {"white", "black"}` enumerates in tlc2's INTERN
   order (`"white"` first) and in string order here (`tlc-value-order`), so
   the random index into the 262,144 initial states lands on a different
   state (the probe's `color` values are exactly inverted). EWD840_anim now
   reports the manifest's safety failure (AnimInv) through a different
   behavior; EWD687a_anim still reaches a liveness failure first.
