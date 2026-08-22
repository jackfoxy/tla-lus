# R1.1 remainder — tier-2 coverage the unit deferred — measurement notes

Parent plan: `~/FoxyLabs/tla-lus/R1.1-remainder-plan.md` (.R0–.R4).
Oracle pin: `tlaplus@4ba7d8811`, `tlaplus-Examples@47b0e2cc0`.

## R1.1.R0 — kickoff (docs / measurement only)

Four questions, all four answered by measurement rather than by reading the row.
**Three of the four answers contradict what the committed docs say.**

### (a) The embedding wall does not exist

`doc/testing.md`, the R1.1.9 breakdown row and the `gen-tier2-tests.py` NB all say the same thing:
the 15 subdir specs over `SUBDIR_CLOSURE_MAX` are "past the embedding limit" and "would need
Clay-read, which the ship's test framework cannot do". **Measured false.** Both steps below ran on
`tla-zod` against desk rev 867/870, from pier-only shards (nothing added to the repo).

| step | shard | bytes | arms | result |
|---|---|---|---|---|
| 1 | the 15 monsters alone | 476,598 | 1 | `|commit` clean, `built`, `test-sany-mon-1` **OK in 365.5 s**, 15/15 agree with Java |
| 2 | all 310 specs, cap raised 16,000 → 70,000 | **1,338,467** | 6 × 55 | `|commit` clean, **`built`**, all 6 arms **OK**, `ok=%.y`, **310/310 agree**, 1,683 s |

The largest single embedded closure is `suite/test211` — 63,594 raw bytes in **one** module, 66,390
after `+hcord` escaping. It embeds, builds and analyzes. There is no per-file, per-arm or per-build
failure to report, because nothing failed: the cap was never measured, and 16,000 is simply where
R1.1.7–.9 stopped raising it.

Census behind the numbers (pure Python, no ship):

```
310 in-scope subdir specs whose module closure resolves
  295 under 16,000   raw 776,481   escaped 838,445
   15 over  16,000   raw 440,528   escaped 474,416
```

| closure | esc | mods | spec |
|---|---|---|---|
| 63,594 | 66,390 | 1 | `suite/test211` |
| 52,131 | 55,732 | 4 | `VoteProof/MC` |
| 50,802 | 53,736 | 3 | `examples/acp/ACP_NB_TLC` |
| 31,795 | 36,265 | 2 | `CodePlexBug08/EWD840MC1` |
| 29,712 | 31,132 | 3 | `examples/detector_chan96/EnvironmentController` |
| 25,388 | 26,622 | 2 | `VoteProof/Consensus` |
| 24,923 | 26,094 | 1 | `examples/Prisoners/Prisoners` |
| 21,905 | 23,528 | 2 | `examples/acp/ACP_NB` |
| 21,786 | 25,386 | 2 | `CodePlexBug08/AgentRingMC` |
| 21,451 | 22,360 | 1 | `VoteProof/TLAPS` |
| 21,313 | 22,550 | 4 | `examples/locks_auxiliary_vars/LockHS` |
| 20,863 | 25,723 | 2 | `symmetry/OneBitMutex/OneBitMutexNoSymmetryMC` |
| 19,744 | 21,213 | 2 | `examples/acp/ACP_NB_WRONG_TLC` |
| 19,011 | 20,261 | 3 | `EWD998/EWD998Chan` |
| 16,110 | 17,424 | 4 | `simulation/NQSpec/MC` |

**All 15 agree with Java** (every one `accept`, Hoon `accept`) — so `.R2` adds 15 specs of coverage
and **zero** census entries. Combined SANY coverage goes 403/437 → **418/452 embedded specs**, and
the subdir batch becomes 310/310.

**The real constraint is cost, not capacity.** The 15 cost 365 s of ship time when run alone —
~24 s/spec against ~4 s/spec averaged over the 310, and the whole 310-spec shard runs in **1,683 s**
across its six arms (335 / 323 / 317 / 268 / 241 / 199 s). That is a nightly-tier budget question,
not a Clay question.
The third candidate route in the plan (drive them through Clay, a new dojo-driven harness) is
**not needed and should not be built**.

`.R2` is therefore: raise `SUBDIR_CLOSURE_MAX` to 70,000, regenerate, update the census prose in
`testing.md`/`tier2.py`, and retire the "need Clay-read" claim wherever it is written down. The
number to record is **1.34 MB embeds and builds**; the cap is a runtime-budget knob.

### (b) What the goldens carry that nothing compares

Six goldens, 63 lines total, in `desk/test-data/tier2/oracle/`. `+norm_tlc` projects verdict,
`STATES <gen> <distinct> <queue>`, `DEPTH`, and the labelled `TRACE`.

| golden | lines | SANY arm | TLC arm | carried but never compared |
|---|---|---|---|---|
| `Empty` | 2 | ✓ | — (no cfg) | nothing |
| `DieHard` | 41 | ✓ | ✓ | `DEPTH`, generated count, **35 TRACE lines / 7 labelled states** |
| `HourClock` | 5 | ✓ | ✓ | `DEPTH`, generated count |
| `TCommit` | 5 | ✓ | ✓ | `DEPTH`, generated count |
| `CigaretteSmokers` | 5 | ✓ | **none** | the whole TLC section |
| `SimpleAllocator` | 5 | **none** | **none** | the whole file |

The comparator (`+tlc-sum`) keeps the verdict line and the `distinct`/`queue` counts and throws the
rest away. To size what wiring it up buys — and what it costs — a pier-only shard ran the 3 curated
TLC specs, the 2 uncompared curated goldens and the 14-spec safety batch and dumped the **full**
counts line, the depth line and (for `DieHard`) the whole rendering.

**`DEPTH` is free.** 15 of 15 comparable cases match exactly (the two initial-state violations,
`Github1145b` and `Github746`, print neither counts nor depth on both sides — an empty-vs-empty
match). Adding the depth line to `+tlc-sum` is pure coverage with no expected divergence.

**The `TRACE` is where the value is, and it is not free.** `DieHard`'s port rendering carries all
seven states, the right values, and **per-action labels byte-identical to the golden** —
`<FixWater line 58, col 16 to line 60, col 58 of module DieHard>` and its two siblings, in the right
order. That is the R1.5.4 `getActions` decomposition landing exactly as claimed. Two rendering
divergences remain, both real port bugs and both new information:

1. **No `/\ ` conjunct prefix.** TLC renders a multi-variable state as `/\ action = "nondet"` per
   line; the port renders `action = "nondet"`.
2. **Variable order.** The port emits alphabetical order
   (`action, bigBucket, smallBucket, water_to_pour`); TLC emits **declaration** order
   (`action, smallBucket, bigBucket, water_to_pour`) — `TLCState.toString`, named as a residue back
   in P2-7.4 and never closed.

Neither is visible to the mc corpus (single-variable or already-alphabetical specs), which is why
`tlc-safety-trace` reads `parity`. `.R1` will find them; they are its work, not a surprise.

**Two goldens have no arm because the port cannot run them** — not recorded anywhere until now, and
absent from `TLC_DIVERGENCES`:

- `CigaretteSmokers` → `Error: unsupported operator-valued argument` (the `ChooseOne(S, P(_))`
  higher-order operator parameter; SANY has accepted it since R1.3.1, the evaluator refuses it).
- `SimpleAllocator` → `Error: TLC cannot handle the temporal formula line 73, col 6 to line 73,
  col 51 of module SimpleAllocator`.

`.R1` must either census both or close them; leaving a captured golden with no comparator and no
census entry is the gap that let this sit unnoticed.

### (c) `+drop-gen` is still load-bearing — keep it

The plan's hypothesis was that the generated-count drop is a stale workaround. **It is not.** Over
the 17 cases that produce a counts line, the generated count diverges on two:

| spec | Java | Hoon |
|---|---|---|
| `DieHard` | 252 states generated | **253** |
| `Continue` | 3 states generated | **4** |

`distinct` and `queue` agree everywhere. Removing `+drop-gen` today turns `test-tlc-diehard` — a
green arm — red.

The comment's own explanation is also too broad: it says "off-by-one on a violation", but five other
invariant violations in the batch (`ConstantOperatorConfiguration`, `DepthFirstErrorTrace`,
`DistributedTrace`, `Github743`, `TraceWithLargeSetOfInitialStatesTest`) match exactly. Whatever the
cause, it is narrower than "a violation" and is **not** discharged by `tlc-safety-stats` reaching
`parity`: that row asserts "generated/distinct/queued/depth byte-match TLC" on the mc corpus, where
these two specs do not appear. So the ledger row carries an unrecorded residue.

`.R1`'s decision: keep the drop, replace the vague comment with the two measured cases, and treat
the counter itself as an optional target — the honest alternative to a silent projection is a named
two-spec residue.

### (d) The two discharged items really are discharged

- **TLC liveness batch** — wired: `TLC_LIVENESS_BATCH` is 9 specs, `test-tlc-liveness-batch` asserts
  `TLC_LIVENESS_DIVERGENCES`, and that list is **empty**, so the arm asserts 9/9 agreement and fails
  if a divergence appears or a known one is fixed. Green in the last full suite (R1.2.7 close-out,
  2026-08-19, 1851 OK / 0 FAILED); not re-run in this increment.
- **`Tool.getActions`** — landed and *observed*, not merely believed: `+get-actions`,
  `+get-actions-list`, `+edge-action-label` and `+edge-action` are in `lib/check`, and `DieHard`'s
  seven per-disjunct trace labels match the golden byte-for-byte (above). This is the strongest
  available evidence and it is a measurement.

One correction: the plan cites "R1.5.12b" for `tlc-safety-trace` parity. R1.5.12b is real but is
recorded only inside the ledger cells (it closed the **wire** trace and the out-degree
distribution); the per-action console labels this increment verified came from **R1.5.4**, and the
`\E` span from R1.5.12. The citation does not change any conclusion.

### Ship-run ledger for this increment

All shards were pier-only (`/mnt/mars/piers/tla-zod/tla-lus/tests/lib/`), committed, measured, and
removed; **no repo file changed except this note**.

| shard | what it measured | outcome |
|---|---|---|
| `tier2-mon.hoon` (476 KB, 1 arm) | 15 monsters embed + agree | OK, 365.5 s, 15/15 |
| `tier2-cnt.hoon` (30 KB) | full counts + depth over 19 specs; whole `DieHard` rendering | FAILED by design (dump arms) — data in (b)/(c) |
| `tier2-full.hoon` (1.34 MB, 6 arms) | the 310-spec file builds **and runs** | `built`, 6/6 arms OK, `ok=%.y`, 1,683 s (335 / 323 / 317 / 268 / 241 / 199) |

One Hoon gotcha re-hit while writing the measurement shard: wide-form `?-(-.r %|  a, %&  b)` is a
syntax error (double space in wide form) — the tall `?-` is required, as the generator already uses.

`tools/tier2.py --check` re-run after the increment: **OK** — inventory, curated oracle and both
comparator shards reproduce byte-identically from the pins. Nothing generated changed; `.R0` touched
no generator.

## R1.1.R1 — compare the trace and the depth

The comparator grew from `[verdict, distinct-counts]` to the whole projection the goldens carry:
verdict, the distinct/queue counts, the `DEPTH` line, and every labelled `TRACE` line. It was
expected to find real divergences rather than to pass, and it found three.

### 1. The `/\ ` conjunct prefix — FIXED

`TLCStateMut.toString` has two branches and the port only had one:

```java
if (vlen == 1) { result.append(key + " = " + Values.ppr(val) + "\n"); }
else { for (...) result.append("/\\ " + key + " = " + Values.ppr(val) + "\n"); }
```

The port rendered every state bare. **Nothing in tier 1 could see it**: the only multi-variable mc
case (`mc/twobit`, `VARIABLES a, b`) completes without a violation, so it has no trace; the whole
`liveness-lasso` corpus is single-variable; and `safety/diamond/out.txt` — which does carry
`/\ a = 0` — is oracle-only, never compared. `+render-state` now takes the variable order and
renders bare for one variable, conjunct-list for two or more.

### 2. The unnamed action prints `Action`, not `Next` — FIXED

`DepthFirstErrorTrace` is `Spec == (x=0) /\ [][x'=x+1]_<<x>>` — no named next-state operator at
all. tlc2 labels its trace steps `<Action line 6, col 21 to line 6, col 26 of module …>`; the port
said `<Next …>`, same span. The cause is one branch of `Action.java`:

```java
public final Action getLocation() {
  if (isNamed()) return getLocation(actionName.toString());
  return getLocation("Action");            // opDef == null → UNNAMED_ACTION
}
```

A `SPECIFICATION`-derived next has no `OpDefNode`, so it is unnamed and prints the generic
`"Action"`. The port hard-coded `'Next'` as the root name at every `+get-actions` call site. `sctx`
now carries `aname` — `?~(nname 'Action' u.nname)`, i.e. the NEXT operator's name in INIT/NEXT mode
and `Action` under a SPECIFICATION — and `+next-span-label` takes the name instead of baking it in.
This was the **entire** remaining safety-batch divergence: `DepthFirstErrorTrace` and
`TraceWithLargeSetOfInitialStatesTest` both close, and the batch is **14/14 on the full trace**.

The job kernel keeps `'Next'`: its sliced continuation does not carry the name, the same gap
R1.8.1.3 already documents there for the stuttering hint. Named in the code at the call site.

### 3. `Github710d` — censused, owned by R1.6

R1.6.6 recorded that a deadlock reached in the state search "ABORTS the run, so its final liveness
check never runs". Measured at the pin, that is not what tlc2 does:

```
Error: Deadlock reached.
Error: The behavior up to this point is:      ... 4 states ...
Error: Temporal property NeverThree was violated.
Error: The following behavior constitutes a counter-example:   ... 4 states ...
4 states generated, 4 distinct states found, 0 states left on queue.
```

The final liveness check DOES run (`Implied-temporal checking--satisfiability problem has 2
branches` is printed before the verdict) and reports a second block before the statistics. The
port's pre-emption emits the deadlock report alone. **The verdict is identical**; what is missing is
a second report block, so this is a rendering divergence in R1.6's territory, frozen in
`TLC_LIVENESS_DIVERGENCES` with that cause. Liveness batch **8/9**. `Github710e`, the sibling case,
agrees — its property is not violated, so there is no second block to print.

### What is normalized, and why each is measured rather than assumed

**The generated count stays dropped.** R1.1.R0 measured it still diverging on `DieHard` (253 vs 252)
and `Continue` (4 vs 3). Removing `+drop-gen` would turn a green arm red.

**Each state's bindings are sorted, on both sides.** This is the one thing R1.1.R0 called
"alphabetical vs declaration order" and it turned out to be neither. tlc2's order is
`SpecProcessor`'s `rootModule.getVariableDecls()`, which is `Context.getVariableDecls()` walking a
**`java.util.Hashtable`**'s buckets and `ModuleNode` reversing the result. Solving for it on
`DieHard` (source order `bigBucket, smallBucket, action, water_to_pour`; printed order
`action, smallBucket, bigBucket, water_to_pour`):

| capacity | bucket indices | resulting order |
|---|---|---|
| 11 | 4, 3, 3, 0 | water_to_pour, smallBucket, action, bigBucket |
| 23 | 5, 19, 15, 4 | water_to_pour, bigBucket, action, smallBucket |
| 95 | 62, 93, 90, 36 | water_to_pour, bigBucket, action, smallBucket |
| **191** | 188, 168, 75, 189 | **action, smallBucket, bigBucket, water_to_pour** ← TLC's |
| 383 | 116, 44, 200, 140 | smallBucket, bigBucket, water_to_pour, action |

Exactly one capacity in Hashtable's 11/23/47/95/191/383 growth sequence reproduces it. Since the
capacity is a function of the total symbol count of the module context — every operator an EXTENDS
drags in — reproducing the order means emulating a Java hash table. It carries no meaning, so it is
an **approved difference** (`doc/compatibility.md`) and both sides sort. The port renders
declaration order, which is at least stable.

A consequence worth recording: the same `vars[i]` array drives `TLCStateMut.fingerPrint`, so
`+var-order`'s comment claiming source order is "TLC's canonical … order, which fixes the FP64
state-fingerprint byte order" is **wrong about being TLC's**. A spec whose declaration order differs
from its context order fingerprints consistently differently — a different internal identity for the
same state partition, never a different verdict or count, and unobservable in every current golden
(all single- or two-variable, where the orders coincide).

### One bug in the comparator itself, caught before it was committed

The first Java-side projection captured `Finished checking temporal properties in 00s at
2026-08-22 09:26:00` as a trace line. That is a **timestamp**: it would have baked the generation
time into the frozen shard and broken `tier2.py --check` on the next run. The trace section now ends
at the counts line *or* any `Finished` line.

### Gates

Tier-1 shards re-run after the `check.hoon`/`job.hoon` changes, all green: `mc`, `trace`,
`liveness-lasso`, `liveness-message`, `safety-gen`, `inv-constraints`, `symmetry`, `stats`, `job`,
`spec-decomp`, `tests/app/tla-lus`. Tier 2: `test-tlc-diehard`, `test-tlc-hourclock`,
`test-tlc-tcommit` and `test-tlc-batch` green on the full projection; `test-tlc-liveness-batch`
asserts the one frozen `Github710d` entry. Goldens unchanged — only the comparator grew, exactly as
the plan required.

## R1.1.R2 — the monsters

`.R0` measured the wall and there isn't one, so this is the cheap route the plan's option 1 named:
`SUBDIR_CLOSURE_MAX` 16 000 → **70 000**, regenerate, and retire the claim wherever it is written
down. No new harness, no Clay route.

| | before | after |
|---|---|---|
| subdir specs compared | 295 | **310** (every in-scope spec whose closure resolves) |
| `tier2-sub.hoon` | 862 812 B, 6 arms | **1 338 723 B**, 6 arms |
| subdir agreement | 295/295 | **310/310** |
| combined SANY | 437 specs | **452** (142 flat + 310 subdir), all agreeing |

The 15 arrive with **zero** census entries — `.R0` had already run them and every one agrees with
Java (all `accept`). So the cost of this increment is entirely runtime: ~24 s/spec for the 15 against
~4 s/spec averaged over the 310, about +365 s on a nightly arm.

### What the cap means now

It is a **runtime budget**, not a capacity limit, and the code says so. 70 000 sits above the largest
in-scope closure at the pin (`suite/test211`, 63 594 raw bytes in one module) with headroom, so its
only job is to stop a future upstream spec from silently adding minutes to a nightly arm — a number
to raise deliberately after measuring, which is exactly what R1.1.6–.9 did not do.

### The claim that was retired

Three places asserted the same unmeasured thing — the generator NB, `doc/testing.md`, and the
R1.1.9 breakdown row: that the 15 were "past the embedding limit" and "would need Clay-read, which
the ship's test framework cannot do (no `our`/`now`)". The Clay half is true and irrelevant: tests
still cannot scry Clay, and they do not need to, because embedding was never the constraint. All
three now carry the measured numbers instead, and `doc/testing.md`'s deferral list has the row struck
through rather than deleted, so the wrong unblock condition stays visible next to what actually
unblocked it.

`divergences.txt`'s census header also stopped saying "small-closure": there is no longer a
small-closure subset, it is every in-scope subdir spec.
