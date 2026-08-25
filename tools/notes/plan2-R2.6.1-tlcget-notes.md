# R2.6.1 — TLCGet / TLCSet

The row said: *"Engine state the evaluator does not own today — `TLCGet("level")`
appears in real specs and `PickSuccessor` depends on it. Needs a per-run mutable
slot threaded through the kernel and its continuation."*

Measured, that is half right, and the two halves have very different costs.

## `TLCGet`'s statistic keys need no new engine state at all

`TLCGetSet.TLCGetStringValue` reads:

| key | pin source | port already has |
|---|---|---|
| `level` | `s0.getLevel()` (0 in const/init) | the expanded state's BFS depth |
| `diameter` | `mainChecker.getProgress()`, monotone | `depth.cur` |
| `distinct` | `getDistinctStatesGenerated()` | `distinct.cur` |
| `queue` | `getStateQueueSize()` | `(lent queue.cur)` |
| `generated` | `getStatesGenerated()` | `gen.cur` |

Every one is a number the port's own `bfs-cursor` already holds. Nothing had to
be *acquired* — it had to be *handed over*. `eenv` gains `run=(unit tlc-run:so)`,
set per expansion by `+with-run`, which is R2.4.1's `+with-setmax` idiom: a
setter rather than a `+make-env` parameter, because `+make-env` has ~30 call
sites and only the ones inside a search have anything to say.

`level` is the one that needs no checker: `TLCGetStringValue` tests
`EvalControl.isConst/isInit` **first** and returns `INIT_LEVEL - 1` = 0 before it
touches `mainChecker`. So a constant context answers 0; the four counters raise
EC 2145 there, which is what the pin does when `mainChecker` is null.

`level` is also **not monotone** — the pin's own comment says so, and a probe
shows it walking 1,2,3 / 1,2,3 / 1,2,3 while `diameter` climbs 1,2,3,4.

### Proved by construction, not by a printed number

The port's `PrintT` is a typed rejection (no console channel), so the obvious
probe is unavailable. The mc case `tlcget-level` instead **builds its state graph
out of the value**:

```tla
Next == x < 6 /\ x' = x + TLCGet("level")
```

A wrong level gives a different graph. Port and pin agree exactly: 0 → 1 → 3 → 6,
`Invariant Inv is violated`, 4 generated / 4 distinct / 0 queued, depth 4 — and
the per-state action labels match too. `tlcget-stats` covers the other four keys
through an invariant that reads all of them.

### The trace-label re-solve needed the same value

`+edge-action-label` re-evaluates the next-state relation to attribute each trace
step. Without a level it matched no action and every state printed
`<unknown action>` — the first version of this change shipped exactly that.
A trace position **is** its level (state *i* is at level *i*), so it is
reconstructible; `+render-trace` and `+trace-states` now pass it.

### Absence is expressible on purpose

The four counters sit behind a `(unit ...)`. The label re-solve knows a state's
level but **not** the search counts at the moment that state was generated, and
answering `TLCGet("generated")` with a plausible zero there is precisely the
failure R2.1 exists to prevent. Absent, those keys raise EC 2145 — the same
answer the pin gives with no checker running.

Kept refused, by name:

- `duration` — the wall clock, which no reproducible run may observe.
- `worker`, `seed`, `fingerprint`, `mode`, … — genuinely unreachable state.
- an unknown key — EC 2145, as at the pin.

## `TLCSet` is the expensive half, and it belongs with R2.7.4

Measured at the pin:

```tla
Init == x = 0 /\ TLCSet(0, 100)
Next == ... /\ PrintT(<<"before", TLCGet(0)>>)
           /\ TLCSet(0, TLCGet(0) + 1)
           /\ PrintT(<<"after", TLCGet(0)>>)
```

```
<<"before", 100>>  <<"after", 101>>
<<"before", 101>>  <<"after", 102>>
<<"before", 102>>  <<"after", 103>>
```

So the register **accumulates across state expansions**, and the write is visible
to a later conjunct of the *same* evaluation. It is a run-scoped mutable
accumulator, not part of the checked state.

`eenv` is read-only by construction and `eres` is `(each value eval-err)` — there
is no channel for a write to escape. Supporting `TLCSet` means **every eval's
return type carries the store**.

That is the identical cross-cutting change **`tlc-coverage` (R2.7.4) was re-sized
L/high for**, for the identical reason the R2.0 measurement records: *"`fuel`
decrements DOWNWARD while coverage accumulates UPWARD, and Hoon has no mutable
counter, so every eval's RETURN type must carry it."* An upward-accumulating
quantity has to ride the result.

**Doing R2.6.1's write half and R2.7.4 separately means performing that surgery
twice on the same 90-reference evaluator.**

**DECIDED (2026-08-25): the write half is folded into R2.7.4.** That unit now
owns `TLC!TLCSet`, `TLCExt!TLCGetOrDefault`, `TLCExt!TLCGetAndSet` and closing
`tlc-module-tlc`. All three are refused *by name* here rather than half-built,
and their `r2-scope` verdicts were moved from `R2.6.1` to `R2.7.4` in
`inventory.txt` — the column R2.6.0 made the machine-checked record, so it moves
with the decision instead of drifting from it.

One asymmetry is worth carrying into R2.7.4, because it makes the fold more than
bookkeeping: **coverage counts are engine-internal and unobservable to a caller,
where the register store is READ BACK by `TLCGet(int)`** and can therefore change
a spec's state graph. The same mechanism carries both, but only one of them can
alter a verdict — so the register store needs the differential treatment
(`tlcget-level`'s "build the graph out of the value" shape), not just a
statistics comparison.

## Status

**The sub-unit is closed; the ledger row is not.** R2.6.1 has no work of its own
remaining, so it is marked done. `tlc-module-tlc` stays `approved-difference` —
the read half is at parity and proved, the write half is a named refusal with a
measured reason — and **R2.7.4 owns closing it**. A sub-unit closing and a row
closing are different things, and this row's acceptance was always the row.

Shards green: mc (31, incl. the two new cases), tlcmod, core-eval, stdops,
stdops-diff, node-eval, trace, stream, safety-gen, neval-mc, sim-diff,
inv-constraints, stats, job.
