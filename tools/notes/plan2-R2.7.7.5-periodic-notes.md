# R2.7.7.5 — `_PERIODIC` is a wall clock, and that decides the unit

```text
Sub-unit: R2.7.7.5
Claim being measured: "`_PERIODIC` is verdict-affecting: ModelChecker.java:718
  evaluates it INSIDE the search loop and returns EC.TLC_ASSUMPTION_FALSE when
  false -- the run ENDS. Needs the periodic hook, not just an evaluation."
Measurement result: verdict-affecting, YES. "Inside the search loop", NO -- and
  that is the whole difference. It is evaluated by the PERIODIC-WORK THREAD on
  a wall-clock timer, so its effect is a function of machine speed.
```

## What "periodic" actually means

`doPeriodicWork` is not part of the search. `AbstractChecker` runs it from a
separate loop that `wait`s and then calls it — the same thread that prints
progress reports and takes checkpoints. Whether it runs at all, and how often,
depends on how long the search takes in seconds.

Measured, both directions, same jar and same config:

| spec | `_PERIODIC Falsehood` (always FALSE) |
|---|---|
| 4 states | **the run COMPLETES** — `Model checking completed. No error has been found.` The timer never fires, so the keyword has no effect at all |
| ~4M states | the run STOPS wherever the timer landed: **1 677 194** states in one run, **1 740 872** in the next |

So the same spec and config either complete or abort depending on machine
speed, and when they abort, they abort at a different point each time.

## The decision

**This is `tlc-dfid`'s argument in its strongest form**: tlc2's own answer is
not reproducible, so no port can match it and no oracle can say what matching
would mean. R2.5 met this with "measure which cases vary, drop the varying
part"; here the varying part IS the feature.

The port therefore keeps R2.7.7.1's **refusal by name**, which is reproducible
and honest — it says the engine has no timer thread, rather than implementing
something that would match the fast case and silently diverge on the slow one.
Ignoring the keyword would match a fast run by accident; evaluating it at some
invented point would match nothing.

`cfg-internal-kw` moves `partial` → **approved-difference** on that argument,
with the difference TESTED rather than asserted: `periodic-fast` is an
approved-difference arm whose golden is the pin's completion and whose
assertion is the port's refusal.

## `_RL_REWARD`, the row's other half

Settled earlier and unchanged: the capability is out of scope (its only
consumer is `RLSimulationWorker`, behind a JVM system property), and its NAME
VALIDATION is at parity since R2.7.7.2 — a malformed `_RL_REWARD` aborts a BFS
run at the pin and does so here, byte-exact.

So the row closes with both clauses argued: one excluded capability with
validated names, one wall-clock feature refused by name.
