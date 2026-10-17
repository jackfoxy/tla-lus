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
