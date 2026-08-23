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

## R1.7c — deadlock-in-simulation (the residue, now closed)

Adding a states-generated case under a CONSTRAINT reached a code path nothing had reached before,
because every other sim spec is infinitely extendable (`x' = x + 1` always has a successor). Only a
constraint can empty the successor set.

`SimulationWorker.java:692-698`:

```java
if (nextStates.empty()) {
  if (checkDeadlock) { return ... EC.TLC_DEADLOCK_REACHED ... }
  break;
}
```

So with deadlock checking ON this ends the WHOLE simulation, with the behavior up to and including
the deadlocked state (`getTrace(curState)` — there is no successor to extend by); with it OFF,
`break` just ends that behavior, which is what the port already did. And the temporal PROPERTY is
not checked first: the `return` pre-empts the post-trace path that runs the liveness check — the same
deadlock-over-liveness precedence R1.6.6 established for the exhaustive checker.

`sim-opts` gained the effective flag, `sim-result`'s violation a `%deadlock` kind, and the job kernel
maps it onto the wire's ALREADY-EXISTING `[%deadlock ~]` with tlc2's `Error: Deadlock reached.`
headline. The build caught an asymmetry worth writing down: `[%exhaustive deadlock=?]` ANDs a
request-side toggle with the cfg's (TLC's `deadlock && getCheckDeadlock()`), but `[%simulate ...]`
carries no such toggle on this wire, so there the cfg's CHECK_DEADLOCK is the whole story.

### The accounting after an error is an approved difference

TLC's reported trace and state counts AFTER a deadlock are not reproducible, and the Java says why:

```java
// One would assume to return from this branch to stop the worker from creating
// additional behaviors. However, this is at the discretion of Simulator, which
// checks if the user ran simulation with "-continue".  If not, Simulator
// will signal termination asynchronously.
```

The worker keeps generating behaviors until the Simulator terminates it *asynchronously*, so `num=3`
and `num=5` runs both report exactly `num` traces — the tiny workload lets the worker finish before
termination lands. That is a scheduling race, not a specification. The port stops at the first
deadlock.

So the statistics corpus pins constraint pruning on walks that CANNOT dead-end inside their depth
(bound `x =< 19`, depths 6 and 8 — a dead end needs `x = 19` exactly and 8 steps reach at most 17;
verified at the pin that neither run prints a deadlock), and the deadlock PATH is pinned separately
by `gen-sim-tests`' `deadlock` case, whose trace is deterministic and printed before any of the
accounting matters.

### A measurement error of mine, recorded

I first read those runs as "TLC never deadlocks here" and filed the divergence as a trace-length
statistics problem. It wasn't: my grep filtered for `traces generated|states generated|trace
length|Progress|Finished` and simply did not include `Deadlock`, which TLC was printing all along.
The lesson is narrower than "measure" — it is **grep for the negative case too**, because a filter
built from what you expect to see cannot show you what you did not.

**`op-check-simulate` is now `parity`.** parity 76 → 77, terminal 116 → 117, owed 9 → 8.

## One process note## One process note

The first post-fix `sim-diff` run reported `actconstraint` still crashing, and I read that as a live
failure. It was a run that had raced the `|commit` build. A scratch shard on the settled build gave
`[traces=1 steps=6 gen=8 viol=%.y]` for the identical inputs, and the re-run was `ok=%.y`. **Read a
ship result only from a build you have watched land** — the same class of mistake as the false-idle
"ALLDONE" in R1.1.R4.

---

# R1.7b — the four `oracle-only` value rows

Not simulation; filed here because it ran in the same session. **No code changed.**

`tlc-value-primitive`, `tlc-value-composite`, `tlc-value-except` and `tlc-binders` were the ledger's
only `oracle-only` rows — the manifest's own definition being "goldens are captured from the pin but
no Hoon comparator". That was false for all four, and had been since **R1.4.1**, which built
`tests/lib/core-eval`: every arity-0 definition of every `eval-core` case through
`+project-defs:check`, compared to the `EvalDump` oracle's projection line for line.

The tell was already in the ledger. `tlc-eval-node`'s row says, in as many words:

> **R1.4.1: the `EvalDump` differential is no longer oracle-only**

Four sibling rows cite the same corpora and nobody re-statused them. This is the third time this
session that a row's own claim, unmeasured, was the thing standing in the way — after R1.1.R0's
"embedding limit" and R1.7's `x' \in S`.

## Verified, not inferred

`-test /=tla-lus=/tests/lib/core-eval ~` → **`ok=%.y`, 20/20 arms, 123 compared definitions.** The
only skips anywhere in the shard are three LAMBDA sites in `ev-oparg` (a unit-3 residue); none fall
in these rows' corpora.

Each row's claimed surface was checked against its corpus rather than assumed:

| row | corpora (definitions) | claim checked |
|---|---|---|
| `tlc-value-primitive` | `ev-primitives` (10), `ev-errors` (2) | Bool, Int ±/0, String incl. empty + `\"` escape, Interval incl. empty `5..2` |
| `tlc-value-composite` | `ev-composites` (9), `ev-lookup` (9), `ev-sets` (9), `ev-domain` (11) | tuples/records/functions/sets, nesting, DOMAIN, lookup |
| `tlc-value-except` | `ev-except` (9) | `![2]`, `@`, `!.a`, nested `!.b.c`, tuple `![3]`, multi-clause |
| `tlc-binders` | `ev-binders` (7), `ev-sets` (9), `ev-tupbind` | CHOOSE, `\A`/`\E`, set-builder BOTH forms, CASE+OTHER, IF |

## What was re-filed rather than dropped

Two rows carried trailing claims that belong elsewhere, and saying so is part of the correction:

- `tlc-binders`' "short-circuit + pause/resume pending" — short-circuit is an evaluation-STRATEGY
  property, visible only through the cost-model counters, which are a tested `approved-difference`
  under `tlc-coverage`; pause/resume is the budget/continuation machinery owned by
  `op-check-exhaustive` / `tlc-driver` and tested in `tests/lib/job` + `tests/app`.
- `tlc-value-composite`'s "equality/order/normalization pending" — the projection compares the
  CANONICAL RENDERING, so normalization is exercised (`{3, 1, 2, 1}` renders sorted and deduped),
  while value ORDER and laziness are owned by `tlc-value-order` and `tlc-enum`, both already
  terminal.

Owner columns were repointed from the planned modules (`lib/value (planned 6.2)`,
`lib/eval (planned 6.4)`) to the real ones, as R1.0 did for the eval rows.

## Result

**oracle-only 4 → 0 · parity 72 → 76 · terminal 112 → 116 · owed 13 → 9.** `check-parity.py`
well-formed. No `oracle-only` row remains in the ledger.
