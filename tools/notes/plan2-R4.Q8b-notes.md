# R4.Q8b notes — liveness rest, SmokeEWD998 (2026-10-26)

Plan `~/FoxyLabs/tla-lus/R4-perf-plan-r3.md`, unit Q8b.

## Baseline after QS (`logs/census-q8b0.txt`)

All six liveness-bound rows from census-q8 were still `limited time`, each
with distinct = manifest (exploration complete). GameOfLife was still
generating (68,659 of 131,072).

## 1. Fairness bits computed once per run, not once per OrderOfSolution

SingleLaneBridge (stage split via `probe2.py`, `%bout` in a ship-only
`lib/job`): explore 97 s; liveness 8 OrderOfSolutions, each a product of
≈10.8k nodes at ≈31 ms per node (a dozen `<A>_vars` leaves evaluated on
every edge). The same fairness leaves stand in every OOS, but their `~+`
entries (≈240k act-evals) cannot survive the bounded cache.

- `pcursor` gains `ab`: per-edge checkAction bits by `[fp0 fp1]`
  (`+edge-bits`). `+node-edges` is now iterative, with the same edge order.
- The `%live` continuation gains `lc` (`lcache`): the finished OOS's
  `cb`/`ab`, seeded into the next OOS when its checkState/checkAction lists
  are the same (`+seed`).

SingleLaneBridge: liveness > 800 s → 186 s; **success 283–285 s**.

## 2. The no-tableau product built in one slice

ReadersWriters has one OOS with no tableau. `+do-scan` built that OOS's
whole labeled product and searched it in one slice: the whole liveness
phase was a single Gall event of over 13 minutes, which also overran the
wall by ≈130 s. It also re-solved every state's successors, which the
graph build had already recorded.

`+flat-step` builds the no-tableau product a budget of states at a time,
with the same nodes and the same edges in the same order (per state:
stutter self-edge, then successors). It reads the recorded successors
(`sm`) and the `cb`/`ab` caches. `+product-init` seeds it with every state
in `+labeled-product`'s map order. The console path (`+labeled-product`) is
unchanged, and the kernel-vs-console report tests still agree.

ReadersWriters: **success 794 s** (explore 294 s, liveness 500 s).

## 2b. The lasso search: 256 PEMs per OrderOfSolution

ElevatorLivenessMedium (4,122 states, tlc2 10 s): 6 OrderOfSolutions, each
with 256 PEMs (8 weak-fairness conjuncts), and every PEM has its own
EAAction list. `+lasso-of-product` ran adjacency + Tarjan + acceptance per
PEM in one slice: 448 s for the first OOS, then the wall.

- The EAAction edge filter works on masks: each edge's checkAction bits
  become one atom once per OOS, then one `dis` per edge per PEM.
  `+adj-of`/`+scc-internal` had indexed a `(list ?)` per bit.
- Per-vertex out-edge lists (`oa`, in `+adj-of`'s order) are built once per
  OOS. `+tarjan-g` takes a successor gate filtered on the fly, and visits
  only vertices with an EAAction out-edge. Any other vertex is a trivial
  component that is never accepting, and leaving it out changes neither
  the other components nor their order. Tarjan per PEM ≈1.4 s → ≈90 ms.
- `+scc-accepting-in` tests AEState/AEAction/EAAction on ORed or per-edge
  masks: the same predicate, without per-bit list walks.
- The lasso search is sliced by PEMs (`+lasso-step`, `lp` on `pcursor`),
  budget/16 PEMs per slice. PEMs are searched in order and the first lasso
  wins, so contiguous chunks answer as the whole list does. Arm
  `test-kernel-report-pem-slices` compares the kernel at budget 1 and 256
  with the console report, both for a property that holds and for one that
  fails.

Per OOS the lasso search went 448 s → ≈200 s, now in ≈10 s slices. The job
stops at its wall (904 s) instead of minutes past it. It still does not
complete. Per PEM ≈0.3 s remains, mostly the acceptance test on ≈4,000
singleton components that each carry their stutter self-loop. Making that
exact and order-preserving (the reported lasso depends on component order)
is left open.

## 3. SmokeEWD998 (EC 2214) and PROPERTYs in simulation

SmokeEWD998 simulates with `PROPERTY TDSpec` (`TD!Spec` =
`Init /\ [][Next]_vars /\ WF_vars(..)`). The job's simulate branch normalized
the whole first PROPERTY into the temporal engine (no fairness), and that
fails on `[][Next]_vars` with EC 2214. The exhaustive path and the console
simulator bin properties first.

Measured at the pin (`-simulate`, fixed seed):

- an implied action is checked on every generated successor after the
  invariants (`Error: Action property <span> is violated.`, EC 2112);
- a box-state PROPERTY is an invariant (`Error: Invariant BoxP is violated.`);
- an implied INIT is not checked at all in simulation (`x = 1 /\ ...`
  against `Init == x = 0` passes);
- a CONSTRAINT that fails to evaluate ends the run with its error.

Changes:

- `sim-opts` gains `iacts`. `+sim-nexts`/`+sim-nexts-prob` check them after
  the invariants. The violation kind `%action` is rendered `Action
  property ... is violated.` and typed `[%action name]`.
- Both simulate paths append the box-state properties (`binvs`) to the
  invariants.
- The job's simulate branch normalizes only the temporal bin, under the
  spec's fairness, as the console simulator does.
- A CONSTRAINT/ACTION_CONSTRAINT evaluation failure ends the run (`err`)
  instead of dropping the successor. That dropping had masked SmokeEWD998's
  refused `TLCGet("duration")` as a clean run of one-state behaviors
  (`success`, 4,204 generated).

SmokeEWD998 now ends in the approved refusal (R4.2h: `TLCGet("duration")`
reads the wall clock).

Tests: `tools/gen-sim-tests.py` cases `iact`, `iactmix`, `boxprop`
(oracle goldens; sim-diff 88 → 100); `test-sim-prop-kinds` (%action /
%invariant / none for an implied init); `test-sim-constraint-error-ends-run`.

## Gates, census, incident

Census `logs/census-q8b.txt` (the 16 standard rows + the 6 liveness rows +
SmokeEWD998): every count unchanged; SimpleAllocator 161 → 49 s;
SingleLaneBridge success; SmokeEWD998 the approved refusal. validate's only
drift is `desk/doc/evidence-counts.md` (sim-diff 88 → 100 cases, compared
1,376 → 1,388), scaffold-gate and test-examples PASS.

ReadersWriters is at the wall: success at 794, 796 and 873 s, `limited time`
at 910 s on the final code (`logs/census-q8b-final.txt`, a slower session
after the restart -- SimpleAllocator 81 s there against 49 s).

2026-10-26 20:53: the serf aborted during the final regression (`lib/tlcmod`,
an ordinary test shard): `Assertion 'u3_none != veb' failed in
allocate.c:775`, `bail: oops`. Snapshot backed up
(`tla-zod-chk-backup-2026-10-26-2053`); the user chose a normal restart,
which replayed cleanly to event 267895. The remaining six shards then
passed (65/65 across both runs) and the mount matched the repo.
