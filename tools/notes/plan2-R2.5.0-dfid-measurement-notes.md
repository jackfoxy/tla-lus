# R2.5.0 — DFID: measurement

R2.5 is "DFID run mode", sized L by R2.0 (~1,736 Java lines: `DFIDModelChecker`
807 + `DFIDWorker` 246 + the `FPIntSet`/`MemFPIntSet`/`MultiFPIntSet` family
683). Per the standing rule this unit opens by measuring the row's claims before
building on them. It found one fact that **changes what parity can mean for this
row**, and pinned the whole output contract.

## 1. TLC's own DFID output is NOT a function of the specification

`DFIDWorker` picks the next state to descend into **at random**:

```java
private final int getNext(TLCState curState, long cfp) {
  ...
  int index = (int)Math.floor(this.rng.nextDouble() * len);
```

and its generator is seeded from the clock, not from `-seed`:

```java
this.rng = new RandomGenerator();          // java.util.Random()'s no-arg seed
this.rng.setSeed(this.rng.nextLong());
```

`public RandomGenerator() { this.aril = 0; }` — no `super(seed)`, so the
underlying `java.util.Random()` seeds itself uniquely per instance. **`-seed`
does not reach this generator**; it feeds `RandomEnumerableValues` and the
Simulator, neither of which the DFID worker consults.

Measured, six runs of the same TLC on the same spec (`x' = x+1 \/ y' = y+1`,
`INVARIANT x + y < 3`, `-dfid 8 -workers 1`), reporting the counterexample:

| run | trace |
|---|---|
| 1 | (0,0) (0,1) (0,2) (1,2) |
| 2 | (0,0) (1,0) (2,0) (3,0) |
| 3 | (0,0) (0,1) (1,1) (2,1) |
| 4 | (0,0) (0,1) (1,1) (2,1) |
| 5 | (0,0) (0,1) (0,2) (1,2) |
| 6 | (0,0) (0,1) (0,2) (1,2) |

Three different counterexamples from one unchanged input, and no flag makes it
reproducible.

**Everything else is stable.** The same six runs agree byte-for-byte on every
count, and five runs of a non-violating spec hash identically:

```
Finished computing initial states: 1 states generated, with 1 of them distinct.
Starting level 2: 1 states generated, 1 distinct states found.
Starting level 3: 3 states generated, 3 distinct states found.
Starting level 4: 9 states generated, 6 distinct states found.
18 states generated, 9 distinct states found.
```

### What this does to the row's acceptance

The DFID **trace cannot be a byte-parity target** — not because the port's
engine differs, but because *the oracle disagrees with itself*. That is a
stronger case than `tlc-coverage`'s (an engine-internal count a different
evaluator cannot reproduce); here two runs of the *same* engine on the *same*
spec produce different output.

So R2.5's acceptance should be: **byte-exact on the verdict, the per-level
progress lines and every count; the counterexample trace an
`approved-difference` with this measurement as its justification.** Any plan to
differentially test the DFID trace against the pin is unachievable and should
not be written into the unit.

## 2. The output contract, pinned

DFID does not reuse the BFS reporter. Measured line by line:

| | BFS | DFID |
|---|---|---|
| init line | `Finished computing initial states: 1 distinct state generated at <time>.` | `Finished computing initial states: %1% states generated, with %2% of them distinct.` (EC 2208) |
| progress | `Progress(N) at <time>: …states left on queue.` | `Starting level %1%: %2% states generated, %3% distinct states found.` (EC 2205) |
| final counts | `%1% states generated, %2% distinct states found, %3% states left on queue.` | `%1% states generated, %2% distinct states found.` (EC 2204) — **no queue term** |
| depth line | `The depth of the complete state graph search is N.` | **absent** |
| outdegree line | `The average outdegree of the complete state graph is …` | **absent** |

Three EC codes the port's `+ec-body` does not yet carry: **2204, 2205, 2208**.

**The trace has no action labels.** BFS prints `State 1: <Initial predicate>`
and `State 2: <Next line 5, col 9 … of module dfv>`; DFID prints the ordinal and
nothing else. And the two DFID printers differ from each other in whitespace,
which a renderer has to reproduce:

- invariant violation: `State 1: ` — colon **plus a trailing space**
- deadlock: `State 1:` — colon, **no trailing space**

(`printInvariantTrace` goes through `printInvariantViolationStateTraceState`,
`printErrorTrace` through `printRuntimeErrorStateTraceState`.)

## 3. A bounded run ends with NO verdict line

`-dfid 2` on a graph of depth 4:

```
Finished computing initial states: 1 states generated, with 1 of them distinct.
Starting level 2: 1 states generated, 1 distinct states found.
2 states generated, 2 distinct states found.
Finished in 01s
```

There is **no `Model checking completed. No error has been found.`** — the
search stopped at the bound without completing. `-dfid 0` explores only the
initial states and likewise prints no verdict. So a truncated DFID run maps to
the port's `%limited %depth`, not to `%ok`; reporting `%ok` there would claim a
completed search TLC did not perform.

The completion line DOES print when the graph is exhausted inside the bound
(`-dfid 10` on the depth-4 cycle).

## 4. Liveness is refused, with an exact message

Confirmed (`DFIDModelChecker.java:67`). A real temporal property
(`SPECIFICATION Spec` + `PROPERTY <>(x = 2)`) under `-dfid`:

```
Error: Depth-First Iterative Deepening mode does not support checking liveness
properties (https://github.com/tlaplus/tlaplus/issues/548).  Please check
liveness properties in Breadth-First-Search mode.
```

Note the **double space** before `Please`. The same spec runs to
`Model checking completed.` under BFS.

**A `[]P` box-state property is NOT refused** — it routes to the invariant path,
so `PROPERTY` alone does not imply the refusal. The port's own box-state
routing (R1.8.9) means it must make the same distinction: refuse on a genuine
temporal property, run on a box-state one.

The multiple-worker refusal on the line above is not portable — the port is
single-worker by construction — so it has no analogue.

## 5. The visited set, and why it is what makes this L

`MemFPIntSet` maps a fingerprint to a **status word**, not to a boolean:

- bit 0 `DONE`
- bit 1 `LEVELED`, compared against a global `Leveled` that **alternates**
  `2, 0, 2, 0…` on every `incLevel()`
- bits 2+ the level at which the state was last reached

with `isCompleted(s) = (s & 2) == Leveled || (s & 1) == 1` and
`isLeaf(s) = s == NEW || (s >>> 2) == Level`. `getNext` descends only into a
successor that is `!isCompleted` **and** whose recorded level is greater than
the current one — i.e. a state already reachable in fewer steps is not
re-expanded, while one first seen deeper is.

The port's BFS `seen` is `(map @t [depth pred])` and cannot express this: the
parity trick exists so a level sweep can invalidate the previous sweep's
"completed" marks in O(1) rather than clearing the set. This is the "different
visited set" R2.0 identified, and it is the reason the row is L rather than a
variation on `+bfs-step`.

## 6. What is left to build

Nothing in this note is implemented; it is the measurement sub-unit.

- `dfid-opts` / `dfid-cursor` (leveled status map, explicit DFS stack, level,
  counters) and a budgeted `+dfid-step`, mirroring `+bfs-step`'s slicing so the
  mode is resumable like every other
- the status-word helpers of §5
- the DFID reporter of §2 (three new `+ec-body` codes, no queue/depth/outdegree
  terms, unlabeled trace with the two whitespace forms)
- the `%limited %depth` outcome of §3
- the liveness refusal of §4, keyed on a genuine temporal property rather than
  on `PROPERTY` being present
- a `check-mode` arm, the job stage and kont, and the request literals that come
  with any `sur` change

Sizing after measurement: **L stands**, with one scope reduction (no trace
differential, §1) and one scope addition the row did not name (the reporter is a
separate one, §2, not a parameterization of the BFS reporter).


# R2.5 (engine) — landed partially; one divergence open

Built after the measurement above. `lib/check` gained the DFID engine: the
status-word helpers (`+set-status`, `+set-leveled`, `+is-completed`, `+is-leaf-st`,
`+st-level`), `+$ dfid-opts` / `+$ dfid-cursor` / `+$ dfid-frame` / `+$ dfid-out`,
a budget-sliced `+dfid-step` that flattens tlc2's level loop and worker sweep
into one resumable step, and `+dfid-spec` as the direct entry point. It compiled
clean on the first build.

## What matches the pin exactly

Differential against `tlc2.TLC -workers 1 -dfid N`, comparing the verdict, every
per-level progress line and both final counts:

| case | expected | port |
|---|---|---|
| 4-cycle, `-dfid 10` | `%ok` 11/4, levels 2:(1,1) 3:(2,2) 4:(4,3) 5:(7,4) | **match** |
| 4-cycle, `-dfid 2` | truncated 2/2, level 2:(1,1) | **match** |
| 4-cycle, `-dfid 0` | truncated 1/1, no levels | **match** |
| deadlock spec, `-dfid 10` | `%deadlock` 6/3, levels 2:(1,1) 3:(2,2) 4:(4,3) | **match** |
| branching spec, `-dfid 3` | truncated 9/6, levels 2:(1,1) 3:(3,3) | **match** |

That covers the multi-level sweep, both bound-truncation shapes (§3), the
leveled-status bookkeeping and the deadlock path.

Two accounting rules were found by the differential rather than by reading:

1. **`numOfGenStates` takes the whole successor vector up front.** tlc2 does
   `this.numOfGenStates.getAndAdd(sz)` before it looks at any successor, so a
   run that stops part-way through a vector still counts the rest. Counting one
   at a time under-reports — the same shape as the R2.4.6 simulation defect.
   Fixed.
2. A golden I transcribed from truncated output said the deadlock case was 7/4;
   re-running the jar in full showed **6/3**, which the port already produced.
   The port was right and the expectation was wrong — re-read the oracle output
   in full before believing a mismatch.

## The open divergence

A run that terminates on an **invariant violation mid-sweep** does not match:
the branching spec at `-dfid 8` gives `%inv` **15/7** where the jar gives
**18/9**. The level lines agree exactly (2:(1,1) 3:(3,3) 4:(9,6)); only the
final counts differ, and only for this outcome.

It is localized: the very same spec and engine at `-dfid 3` — one level below
the violating level, so the sweep completes instead of aborting — matches
exactly at 9/6. So the search and its accounting are right; what differs is
**how much of the sweep has run when the violation fires**, which is a function
of the DFS order.

### Narrowed by two further experiments

**A single-action violating run matches exactly.** `Next == x' = x + 1`,
`INVARIANT x < 3`, `-dfid 10`: the jar reports `%inv` 7/4 and so does the port.
So the abort accounting — counting the whole successor vector up front, stopping
at the first NEW violating successor, the level lines — is right. The divergence
needs **more than one action** to appear.

**`isLeaf` is tlc2's loop condition, not a push guard.** `DFIDWorker.run` is
`while (!isLeaf) { ... }`, so the first descent that reaches the sweep's depth
ends the entire walk from that initial state and the worker returns to
`getInit()`; it does not carry on with the parent's other successors. The port
had been treating it as "do not push this child" and continuing. **Corrected**
— a real fidelity fix on its own terms — but it does not move this case, so the
violation here is reached before any leaf-terminating descent.

### What remains unexplained

At the start of level 4 both sides stand at 9 generated / 6 distinct (the level
lines agree). Through level 4 the jar adds **+9 generated, +3 distinct** before
reporting; the port adds **+6, +1**.

The `+3 distinct` is the puzzle. Every state at level 4 of this spec has
`x + y = 3` and therefore violates, and tlc2 checks an invariant immediately
after `setStatus` returns NEW — so it ought to stop at the *first* violating
state it inserts, i.e. +1 distinct, which is what the port does. Three
insertions before reporting means one of these is false:

- the final `distinct` on a violating run is not `theFPSet.size()`;
- `status == NEW` is reached for fewer successors than assumed (something
  earlier in the per-successor loop skips the check);
- or the level-4 sweep inserts non-violating states the port does not.

The next step is to instrument rather than reason: dump `theFPSet.size()` and
`numOfGenStates` per `doNext` call from a patched jar, or read
`printSummary`/`reportSuccess` to confirm which counters the final line uses,
and compare against the port's sequence on the same spec. **Not resolved.**

Until it is settled the engine is not on the wire: there is no `check-mode`
arm, no job stage and no reporter (EC 2204/2205/2208 are still absent from
`+ec-body`). `tlc-dfid` stays `partial`. Everything else in §2–§4 — the
reporter's exact line shapes, the `%limited %depth` mapping, the liveness
refusal keyed on a genuine temporal property — is measured and ready to build
against the moment the count is right.
