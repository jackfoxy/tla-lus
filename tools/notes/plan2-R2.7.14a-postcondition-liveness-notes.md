# R2.7.14a — POSTCONDITION on the liveness path

```text
Sub-unit: R2.7.14a (split out of R2.7.14 on 2026-09-01)
Row: cfg-postcondition (stays `partial` — its two original items are .14b's)
Why the split: R2.7.14 was sized as "port TLCExt!CounterExample". The opening
  measurement the row itself demanded found FOUR parts, and the first is
  independent of CounterExample entirely.
```

## The defect, isolated

A postcondition that does not mention the trace at all:

```tla
Live == <>(x = 1)                   \* violated: Next == x' = x
Post == TLCGet("distinct") = 999    \* false
```

| | output |
|---|---|
| pin | counter-example, then `Error: Postcondition Post at line 7, col 9 to line 7, col 32 of module spec is false.`, then the counts |
| port | counter-example, then the counts |

**A run reported `ok` where tlc2 reports a failure** — R2.7.7.0's own finding,
recurring on the one path it did not check. R2.7.7.3 wired the CLEAN report and
the SAFETY-ERROR report; `+check`'s temporal branch returned `report.r`
directly, and the job kernel's `%liveness` stage did the same.

**A comment is why it hid.** `job.hoon`'s `%inv` branch says:

```
::  the %live kont carries no postcondition names: the liveness path
::  keeps them on its own kont, and this branch is the safety
::  violation that pre-empts it (R2.3.4)
```

The `%live` kont had no `pcs` field. The comment recorded an intention as a
fact — the same failure mode as R2.7.12's *"the oos carries no source-property
name"*, and the second time in three units that a confident comment was the
thing standing between the defect and whoever looked.

## Order, measured rather than assumed

A stuttering counter-example under a fairness-free SPECIFICATION prints the EC
2259 hint, so the slot had to be pinned against something with all four pieces:

```text
Error: Temporal property Live was violated.
Error: The following behavior constitutes a counter-example:
State 1..N
State N+1: Stuttering
Warning: The stuttering counterexample above may be caused by ...   <- EC 2259
Error: Postcondition Post at ... is false.                          <- here
8 states generated, 4 distinct states found, 0 states left on queue.
```

So `pcl` goes after `gate` and before `footer` in `+live-render`.

## The clean-run rule holds here too

R2.7.7.3 measured that on a clean SAFETY run a failing postcondition REPLACES
`Model checking completed. No error has been found.` rather than being appended.
Measured again on a temporal property that HOLDS (`Live == <>(x = 0)` with
`Init == x = 0`): same replacement. `+live-render`'s `?~ l` branch now does it.

## The change

- `+live-report` / `+live-render` gain a `pcl=wain` slot (last, after
  `noclose`), rendered between the hint and the counts, and replacing the
  completion line on a clean run.
- Console (`+check`): built from `sctx.pcs` with `rs.bg` and the graph's final
  counts. R2.7.7.4a had already threaded the carrier out of
  `+build-graph-out` for exactly this reason — the render wiring was the only
  thing missing.
- Job kernel: `pcs` added to the `%live` kont, filled from `postconditions.rs`
  at `do-config`; `pcl` built once in `do-scan` from `rs.cur.kk` and passed to
  both `live-render` call sites (the pass branch and the violation branch).
- `+live-message-lines` passes `~`: it is the lasso differential, not the
  production report.

## Evidence

`pc-live-viol` (the isolating case), `pc-live-gate` (the hint ordering),
`pc-live-ok` (the replacement rule) — all byte-exact. 91 `mc` cases. `mc`,
`job`, `liveness-message`, `liveness-lasso`, `cfg-runspec`: `ok=%.y`, 0 FAILED.

## Measured for R2.7.14b, so it does not have to be re-measured

- **`CounterExample` is `TRUE` in `TLCExt.tla`** — a placeholder behind a Java
  `@Evaluation` override. The port evaluates `TRUE.state` today.
- **The value** (`CounterExample.java`) is a record
  `[action |-> set of <<from, actionRec, to>>, state |-> set of <<n, stateRec>>]`,
  `actionRec` being `[name |-> ..., location |-> [beginLine, beginColumn,
  endLine, endColumn, module]]` plus `context`/`parameters` for an action with
  parameters. A lasso-closing edge is appended when `loopOrdinal > 0`.
- **Binding**: only on violation paths, via
  `Context.Empty.cons(counterExampleDef, value)` — four call sites
  (ModelChecker, Worker, LiveCheck, LiveWorker). A CLEAN run evaluates
  `new CounterExample()`, an EMPTY record, which is why `CounterExample.state
  = {}` is the idiom `_JsonTrace` and `_DotTrace` use to detect "no violation".
- **The differential needs care.** Restoring the POSTCONDITION line to
  `gh1389-counting` changes the pin's output NOT AT ALL — it is a silent pass.
  I proved it is evaluated by breaking `Cardinality(S) = 10` into `= 11` and
  getting EC 2404. So each restored fixture needs a deliberately-false variant
  beside it, the both-directions discipline R2.7.6.1's `APPROVED` map
  established. `gh1389-violc` is the stronger acceptance test: it pins the
  state tuples, the edge endpoints AND the lasso-closing edge.
- **`-postCondition mod!op`** targets the same `POST_CONDITIONS` list the
  `.cfg` keyword fills, so the machinery is R2.7.7.3's; what is new is
  `module!operator` CROSS-MODULE resolution. `-dumpTrace` installs
  postconditions through the same list and belongs to `tlc-driver`, not here.
