# R2.7.15 — multi-PROPERTY routing: measured, NOT closed

```text
Sub-unit: R2.7.15
Row: tlc-safety-assume (stays `partial`)
Claim being measured: "the port decides the route from the FIRST PROPERTY
  alone; route the whole list and run the bins alongside each other"
Result: the claim is RIGHT and the SIZING was wrong. A third defect, which the
  row did not name and no existing case could see, moves the fix from "route
  the list" into the SEARCH LOOP -- and, doing so, collapses the row's two
  halves into one change.
```

## The matrix

Six multi-PROPERTY shapes against the pin. `Live == <>(x = 9)`, never
satisfied, in every one.

| case | properties | pin | port |
|---|---|---|---|
| `prop-box-viol` | `[](x<2)` violated, then `Live` | `Invariant BoxBad is violated.` | same ✓ |
| `prop-box-last` | `Live`, then `[](x<2)` violated | `Invariant BoxBad is violated.` | **temporal verdict** ✗ |
| `prop-init-viol` | `x = 5` (level-1), then `Live` | `Property InitBad is violated by the initial state:` | same ✓ |
| `prop-act-ok` | `[][x'=x+1]_x` HOLDS, then `Live` | `Temporal property Live was violated.` | **completes clean** ✗ |
| `prop-act-viol` | `[][x'=x+1]_x` violated, then `Live` | `Action property ActBad is violated.` 2/2/2 | right verdict, **wrong counts** ✗ |
| `prop-box-then-live` | `[](x<9)` HOLDS, then `Live` | `Temporal property Live was violated.` | **completes clean** ✗ (R2.7.12's) |

**Two of the six pass, and both only because their safety-side property is
declared FIRST.** `prop-box-viol` and `prop-box-last` are the same two
properties in opposite orders: the pin gives one verdict, the port gives two.

## Two rules, measured

**Precedence is uniform.** The safety pass — config invariants, box-state
properties, implied inits, implied actions — runs first and pre-empts; the
liveness engine reports only if it completes clean. That is
`ModelChecker.doNext` returning on a violation, i.e. R2.3.4's rule
generalized from INVARIANT to every safety-side bin.

**Routing is order-independent.** Each property is binned on its own shape, so
declaration order changes nothing. The port's head-of-list test makes order
load-bearing, which is why the corpus (uniform in the deciding dimension, as
usual) never showed it.

Also worth pinning: a `[]P` box-state PROPERTY is reported as an
**`Invariant`**, not as a `Temporal property`.

## The third defect, and why it changes the fix

`prop-act-viol`: the port gets the verdict and the trace right and the
**counts wrong** — 5 generated / 4 distinct / depth 4 against the pin's
2 / 2 / 2.

`+implied-action-run` builds the whole reachability graph and then scans it
for the first bad step, so it reports a COMPLETED search's statistics. tlc2
checks `[][A]_v` during the search and stops at the violation.

The arm's own comment says it is *"implemented by giving the BFS the action as
a checked predicate rather than a filter (R1.8.1.1/.2)"*. The code four lines
below says *"build the whole reachability graph, then scan"*. **Intent
recorded as code — the third such comment this release**, after R2.7.12's
"the oos carries no source-property name" and R2.7.14a's "the liveness path
keeps them on its own kont".

`implied-act-viol`, the existing case, could not catch it: its violation is on
the LAST transition, where a completed graph and a stopped one agree.

**Why this re-sizes the unit, and simplifies it.** The row described two
halves — (i) route the whole list, (ii) run the bins alongside each other.
Measured, they are one change: make implied actions a per-transition check
beside `acons`, which is where tlc2 has them and where `+bfs-step` already has
the hook (`?^ prev` … `acon-hold-rs`). Then a single search carries
invariants, box-state properties and implied actions together, the counts
come out right because the search stops, and "alongside each other in one
run" is what the search already does.

## What is owed

1. `iacts=(list [name=@t body=sem])` on `bfs-opts`, checked at the existing
   per-transition hook. ~10 positional constructors to update.
2. An `%action` variant on `outcome`, rendered by `+render-outcome`,
   `+explore-outcome`, `job.hoon`'s `+finish-bfs` and the DFID verdict map.
   The WIRE side is already done — R2.7.13 gave EC 2112 its own
   `[%action name]` violation.
3. The routing loop over EVERY property, replacing the head-of-list test in
   `+check`, `+run-check` and `do-config`. `+implied-temporals` (R2.7.12)
   already does the temporal bin over the whole list; this extends the same
   loop to the other three.
4. `+implied-action-run` and `+first-bad-step` retire with it.

## State

Four `mc` cases frozen with their pin goldens and reasons
(`prop-box-then-live`, `prop-box-last`, `prop-act-ok`, `prop-act-viol`); two
more (`prop-box-viol`, `prop-init-viol`) pass and pin the order-dependence
from the other side, so a fix that breaks them fails too. 96 mc cases,
`ok=%.y`, 0 FAILED. Ledger unchanged at **132 terminal / 2 owed**.
