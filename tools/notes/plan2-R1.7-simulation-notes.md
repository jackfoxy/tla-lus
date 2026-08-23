# R1.7 — Simulation parity (unit 9) — notes

Parent: `R1-release-work-breakdown.md` R1.7. Oracle pin: `tlaplus@4ba7d8811`.
Ledger row: `op-check-simulate`.

**Which unit this is.** R1.7 is Release R1 sub-unit 7, and its scope is SIMULATION — PLAN-2 **unit
9** (`~/FoxyLabs/tla-lus/unit-9-plan.md`). It is *not* `unit-7-plan.md`, which is PLAN-2 Work Unit 7,
single-worker SAFETY model checking, done 2026-07-25. The numbering collides; the units do not. R1.7
has no sub-plan of its own, so this note plays that role.

unit-9-plan's own 9.2 row already recorded both halves of what R1.7 measured:

> **Note:** `x' \in S` is a node-eval residue (unsupported by the exhaustive checker too), not a sim
> gap. CONSTRAINT-in-sim deferred.

All of 9.1-9.6 are ✅ — the constraint item was carried as a NOTE inside a closed sub-unit rather
than as an open one, which is why it reached R1.7 through the ledger row instead of the plan. The
measurement below was taken independently and agrees with that note.

## The residue, as the row stated it

> Still owed: `x' \in S` nondeterministic assignment (a node-eval residue, not RNG), and
> state/action CONSTRAINT handling in simulation.

**One of the two was already closed and nobody had checked.** Same shape as R1.1.R0's finding: a
residue carried as fact across increments, never measured.

## Measurement first

The sim corpus (`gen-sim-tests.py`) had three specs, all `x' = e` with no constraints — so *neither*
residue was covered by any test. Three cases were added and the exact-seeded-trace differential
(`tests/lib/sim-diff`, 5 seeds each) run against `tlc2.TLC -simulate -workers 1`:

| case | exercises | result before the fix |
|---|---|---|
| `nondet` (`x' \in {x+1, x+2}`) | one action yielding TWO successors | **5/5 PASS** — already closed by R1.5.1 |
| `constraint` (`CONSTRAINT x =< 20`) | `isInModel` | 3/5 crash |
| `actconstraint` (`ACTION_CONSTRAINT x' =< x + 5`) | `isInActions` | 5/5 crash |

The crashes are `need` on an empty violation: with the bound ignored the walk runs past the
invariant's trip point, the behavior ends clean, and `viol` is `~`. So the constraint half was real
and the `x' \in S` half was stale — R1.5.1's solver work had covered simulation all along, because
simulation and the BFS share `+next-states:ne`.

## What SimulationWorker actually does

The rule is in the next-state functor, `SimulationWorker.java:560-620`, and the ORDER matters:

1. `isGoodState` — completely specified
2. **`collectPreSuccessor`** — the successor is COUNTED here
3. the invariants, declaration order; a violation throws (the state is never added)
4. the implied actions
5. **`if (tool.isInModel(t) && tool.isInActions(s, t))`** — else the successor is silently dropped

Three consequences the port now reproduces:

- **A pruned successor is still invariant-checked.** The filter runs *after* the invariant, so a
  violation on the constrained-out boundary is still reported. (`+register` already applied the same
  rule in the BFS — R1.5.1 — reached from the other direction: constraint first, then
  `+check-pruned` checks the invariants anyway.)
- **A pruned successor still counts as generated**, because `collectPreSuccessor` precedes the
  filter. `+sim-nexts` therefore returns `ngen` (everything generated) alongside `nx` (the
  survivors), and `+sim-step` counts `ngen`, not `(lent nx)`.
- **An action whose successors are all pruned contributes nothing**, so the retry stride falls
  through to the next action exactly as `hasStates()` (`!nextStates.isEmpty()`) makes it. Those
  generated-then-pruned states still count, so the retry loop accumulates `ngen` across tries and
  the deadlock branch folds it in too.

## Changes

- `+$ sim-opts` gains `cons` / `acons` (mirroring `bfs-opts`).
- `+sim-nexts` takes them plus the predecessor state, applies `+con-hold` / `+acon-hold` (the same
  predicates the BFS uses) after the invariant check, and returns `ngen`.
- `+sim-step` counts `ngen` and folds the deadlock branch's `ngen`.
- `+simulate-spec` and the job kernel's `%simulate` setup pass `cons.c` / `acons.c`.

A constraint that fails to EVALUATE drops the successor rather than raising: the simulation path has
no typed error channel, and the `%|` arm of `+sim-nexts` already made that choice for a solver
failure. Named in the code, not silent.

**Kont shape change.** `sim-opts` is persisted inside the `%sim` continuation, so this widens the
saved noun. `+load-kont` is `;;(kont (cue …))` and all three call sites wrap it in `mule`, so a
continuation written by the older code becomes a typed failure rather than a crash. The wire/state
contract is pre-release and has been changed deliberately before (R1.5.12b did the same to
`run-stats`).

## What R1.7 does NOT close: deadlock-in-simulation

Adding a states-generated case under a CONSTRAINT found a second divergence, distinct from the
filtering residue and left open deliberately.

`gen` matches TLC exactly (24 and 71 on the two runs), so the counting rule above is right. The
**trace-length statistics do not**: TLC reports `mean=8, var(x)=0, sd=0` for three depth-8 behaviors
where the port reports `mean=6, var=5, sd=2`. Measured at the pin with `CONSTRAINT x =< 0`, which
prunes every successor of the initial state:

```
Error: Deadlock reached.
The number of states generated: 7
Progress: 7 states checked, 3 traces generated (trace length: mean=0, var(x)=0, sd=0)
```

**When a constraint empties the successor set, tlc2 reports a DEADLOCK ERROR and stops.** The port's
`%none` branch instead ends that behavior quietly and starts the next one — which consumes the RNG
differently and desynchronizes every later trace, so the whole distribution drifts.

That branch predates R1.7 and no corpus case had ever reached it: every sim spec is infinitely
extendable (`x' = x + 1` always has a successor), so nothing empties the successor set until a
constraint does. The constraint work is what made the path reachable, not what broke it.

Closing it means giving `sim-result`'s violation a `%deadlock` kind and threading it through the job
kernel's typed outcome — a result-shape change with its own wire consequences, which is its own
increment, not a rider on this one. **`op-check-simulate` therefore stays `partial`**, with the
residue narrowed from two items to one named, measured, reproducible case.

The two `constrained` statistics cases assert **states-generated only**, with the reason in the
generated arm: asserting mean/var/sd there would freeze the port's wrong answer as a golden.

## One process note

The first post-fix `sim-diff` run reported `actconstraint` still crashing, and I read that as a live
failure. It was a run that had raced the `|commit` build. A scratch shard on the settled build gave
`[traces=1 steps=6 gen=8 viol=%.y]` for the identical inputs, and the re-run was `ok=%.y`. **Read a
ship result only from a build you have watched land** — the same class of mistake as the false-idle
"ALLDONE" in R1.1.R4.
