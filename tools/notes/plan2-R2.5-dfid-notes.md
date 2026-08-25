# R2.5 — DFID run mode

Depth-first iterative deepening on the wire. `tools/notes/plan2-R2.5.0-dfid-measurement-notes.md`
is the measurement this builds on; it is accurate except where §1 below corrects
it, and that correction is the whole unit.

The unit opened holding an unexplained divergence: a run terminating on an
invariant violation mid-sweep reported **15 generated / 7 distinct** where the
jar reported **18/9**, though every per-level line agreed. The measurement note
ended by proposing to instrument the jar. Two mechanisms explain it, both
readable in the pinned source once you know to look for them, and both absent
from the note, the row and the plan.

## 1. A violation does not stop the walk

`DFIDModelChecker.setErrState` calls `setStop(2)` on every worker. `stopCode` is
tested in **one** place:

```java
public final void run() {
  while (this.stopCode == 0) {        // <-- here
    int index = this.getInit();
    ...
    while (!isLeaf) {                 // <-- and NOT here
      index = this.getNext(curState, cfp);
      ...
    }
  }
}
```

The inner DFS loop never looks at it. So the walk from the current initial state
runs **to its end** — backtracking, descending into the parent's other
successors, expanding the rest of the level's frontier, and counting all of it.
Only when that walk finishes does the outer loop notice and return.

Every later violation is silent: `setErrState` returns false once `errState` is
set, so `printTrace` never runs again — but it still `return`s from `doNext`,
truncating that state's successor vector.

Consequence for parity: **the counts on a violating run are the RUN's, not the
violation's.** Stopping at the violation, which is what the port did and what
every reasonable reading of the code suggests, under-reports.

## 2. `numOfGenStates` is per ACTION

```java
for (int i = 0; i < tool.getActions().length; i++) {
  StateVec nextStates = tool.getNextStates(tool.getActions()[i], curState);
  int sz = nextStates.size();
  this.numOfGenStates.getAndAdd(sz);
```

The measurement note got half of this: "the WHOLE successor vector up front".
The other half is that the vector is **one action's**, and `doNext` loops over
`tool.getActions()`. A doNext abandoned at a violator has therefore counted that
action's whole vector and **none of the later actions'**.

The port had been calling `+next-states` on the merged next-state relation,
which is one vector. That is right for a run that never aborts, which is why
every non-violating case matched, and wrong the moment one does. `dfid-opts`
now carries `acts=(list act)` — the `+get-actions` decomposition — instead of
`next`.

### The discriminating case

`two2` in the corpus. Two actions, the FIRST of which violates:

```tla
A == x' \in {1, 2} /\ y' = y
B == y' = 1 /\ x' = x
Next == B \/ A
Inv == y = 0
```

jar: **2 generated / 2 distinct**. Merged-relation counting gives 4/2, because
it counts A's two successors that tlc2 never generates. Swapping the disjuncts
(`two`) puts the violation last and both schemes give 4/4 — which is why the
first attempt's corpus could not see this.

## 3. `getInit` re-picks

`while (!isLeaf)` exits when a descent reaches the sweep's depth, and control
returns to `getInit()`, which selects any initial state that is **not yet
completed** — including the one just walked, since a leaf-terminated walk levels
nothing on its way out. tlc2 then descends again from the top. The port had been
consuming its `todo` list one initial state at a time.

Invisible on a single-init spec whose sweeps never reach a leaf, which is every
case the first attempt had. `grid-*` in the corpus exercises it.

## What all three have in common

Each is a place where the Java is doing something the *shape* of the code
argues against: a stop flag that does not stop, a counter that looks
per-successor and is per-action, a work list that is not consumed. Reading for
intent found none of them. What found them was hand-simulating the pinned engine
state by state against a spec whose numbers I already had, and asking where the
+9/+3 could come from.

## Verification

`tools/gen-dfid-tests.py` / `desk/tests/lib/dfid.hoon` — 22 cases, each the
normalized output of `tlc2.TLC -workers 1 -dfid N` at the pin:

| case | what it holds down |
|---|---|
| `cyc-complete` | a graph exhausted inside the bound: completion line + 11/4 over four levels |
| `cyc-bound` / `cyc-zero` | both bound-truncation shapes; **no completion line**, so `%limited %depth` |
| `deadlock` | the deadlock path and its `State N:` (no trailing space) printer |
| `branch-viol` | the case that was 15/7; now 18/9 |
| `branch-bound` | the same spec one level lower, where the sweep completes |
| `grid-bound` / `grid-full` / `grid-deadlock` | leaf-terminated walks and `getInit` re-picking |
| `multi-succ` | one action, three successors, the middle one violates: 4/3 |
| `action-order-late` / `action-order-early` | §2's matched pair — 4/4 and 2/2 |
| `init-viol` | EC 2107: `doInit` returns, so NO init line, NO level lines, NO counts |
| `constraint` | CONSTRAINT pruning: pruned states are invariant-checked but not entered |
| `multi-init` | three initial states through `getInit` |
| `box-state` / `live-refusal` | the refusal keys on a genuine temporal property, not on `PROPERTY` |
| `implied-action` | `[][A]_v` checked per TRANSITION in `doNext`, reported as `Action property N is violated.` with the behavior and the counts |
| `implied-init` | a level-1 PROPERTY: the EC 2255 state-level warning, then `Property N is violated by the initial state:` and NOTHING else |
| `inv-beats-action` | both broken on the same transition: tlc2 names the INVARIANT, because `doNext` checks invariants first |
| `alias-trace` / `alias-init` | an ALIAS asymmetry measured at the pin: the DFID **behavior** trace is NOT aliased (`printInvariantTrace` builds a bare `TLCStateInfo` and `StatePrinter` calls `state.toString()`, never `evalAlias`) while the EC 2107 **initial-state** message IS. Pinned so a later "make them symmetric" cleanup cannot quietly alias the trace |

Plus 13 arms in `tests/lib/job` for the wire: the stage plan, `%ok` vs
`%limited %depth`, the violation and its trace artifact, that **no** trace state
carries an action, deadlock, both box-state outcomes, the verbatim liveness
refusal, the `-continue` and `-difftrace` rejections, that the kernel's
`%report` artifact equals the console `+dfid-check` output (so the 22-case
differential covers the kernel path too), and pause/resume identity at every
slice boundary.

Full ship suite green.

## The trace, and how the generator proves it is an approved difference

R2.5.0 measured that the DFID counterexample is not a function of the spec —
`getInit`/`getNext` descend at random from a generator seeded off the clock that
`-seed` does not reach. That justifies an approved difference, but a golden that
simply drops every trace would also hide a real trace bug.

So the generator **measures which cases it actually affects**: it runs the jar 8
times per case and compares the runs to each other. Where the trace varied it is
dropped and the case is marked `nondeterministic` in its `trace.txt`; where it
did not, the trace is compared byte-for-byte. **2 of 22 varied.** The other 20
pin the trace exactly, including the two whitespace forms — `State N: ` with a
trailing space for an invariant violation (`TLC_STATE_PRINT2`, `%1%: %2%` with
an empty info), `State N:` with none for a deadlock (`TLC_STATE_PRINT1`,
`%1%:`).

The marker is **sticky**: once a case has been seen to vary it stays varying, so
a rare disagreement cannot un-mark itself on a later regeneration and make the
generator irreproducible under `validate.py --check`. Two consecutive full runs
produce byte-identical output.

## Scope decisions worth naming

- **The PROPERTY routing is `+dfid-opts-of`'s, and it mirrors tlc2's.** `[]P`
  over a state-level P is appended to the config's own INVARIANT vector, exactly
  as `processConfigProps` appends it, so DFID checks it and does not refuse. A
  level-1 predicate is an implied init, checked per initial state in `doInit`
  (with the EC 2255 state-level warning, through `swarn`). `[][A]_v` is an
  implied action, checked **per transition inside `doNext`** — which is where
  tlc2 checks it, and is more faithful than the BFS path's whole-graph
  `+first-bad-step` scan. Only what is left refuses.
- **`run-stats` reports `queued`/`depth`/`outdeg` as 0.** DFID's summary line
  carries two numbers; there is no queue term, no
  `The depth of the complete state graph search is N.` and no average outdegree.
  Reporting a number the oracle never produced would be inventing one. The
  per-level lines live in the `%report` artifact.
- **`-continue` with `-dfid` is refused by name.** tlc2 supports it there
  (`TLCGlobals.continuation` is read in `DFIDModelChecker.doNext` too); this
  engine records one hit. Refused rather than accepted and ignored (R2.1).
- **`-difftrace`'s refusal was widened** from `?=(%exhaustive -.mode)` to
  `!?=(%simulate -.mode)`, so a new mode cannot slip through a guard written
  against the old two.

## Two bugs the corpus caught in this unit's own code

Both were found by writing the case and measuring, not by review:

- **Invariants before implied actions.** `doNext` checks the INVARIANTS first
  (only for `status == NEW`) and the IMPLIED ACTIONS after, on every transition.
  The first draft had them reversed, so a transition breaking both named the
  action where tlc2 names the invariant. `inv-beats-action` pins it.
- **`%action` uses the UNSPACED printer.** `printTrace` routes **only**
  EC 2110 to `printInvariantTrace`; a deadlock, an action-property violation
  and a runtime error all go to `printErrorTrace`. So `State N: ` (trailing
  space) is the invariant case alone, and the draft printed it for the action
  case too. `implied-action`'s golden carries the difference.

## One Hoon trap, worth recording

`*?` is `%.y`. `=|  cur=dfid-cursor` bunts `stop=?` to TRUE, so the first
`+dfid-spec` returned `%ok 1 1` on every spec — a plausible-looking verdict from
a run that never started. Both flags in `+dfid-cursor-init` are now set
explicitly. This is the failure mode the doctrine's "no fallback returns a
plausible `%ok`" exists for, arriving through the type system rather than
through control flow.
