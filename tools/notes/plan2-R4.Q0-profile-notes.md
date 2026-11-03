# R4.Q0 — re-baseline and profile (2026-10-19/20)

Plan `~/FoxyLabs/tla-lus/R4-perf-plan-r1.md`, unit Q0.

## Census (`tla-zod-tools/logs/census-q0.txt`, `--wall 300`, 52 models)

The 51 small models whose latest row was time-bound, btree, and
MCInnerSerial (MCChangRoberts skipped: a known runaway).

- 5 now complete and equal the manifest: MCParReach 393/747/18,
  MCReachabilityTestRandomGraphs 0/0, MCNanoSmall 3003/6083, SpanTree
  1236/10278, AllocatorRefinement 1690/5854.
- Speed-up each needs to finish inside a **900 s** wall at its 300 s rate
  (a lower bound: a liveness phase can slow it): **23 under 2×** (most
  already enough), **4 at 2–10×** (MCCRDT 5×, MCFindHighest 2×, MCQuicksort
  3×, braf 6×), **6 at 10–100×** (CoffeeCan1000Beans 17×, MultiPaxos_MC_small
  45×, FastPaxos 30×, btree 36×, TLCSailfish1 96×, MCLamportMutex 14×),
  **none over 100×**.
- 14 unrated: 8 sit in ONE %config slice for > 4 min (MCBakery, CarTalkPuzzle
  ×2, MCBinarySearch, MCReachabilityTestAllGraphs, TransitiveClosure,
  YoYoAllGraphs, MC_sums_even; tlc2 needs 1–30 s for each); 3 have no
  manifest count (MCCheckpointCoordinationFailure, SlidingPuzzles ×2) plus
  MCInnerSerial; 2 errors.
- Errors: **LockHS** — `primed variable is unassigned: pc` — FIXED (below);
  **SmokeEWD998** — EC 2214 from the temporal translator; it is a simulation
  model whose `StopAfter` uses `TLCGet("duration")` (refused by name,
  R4.2h), so it ends in that approved refusal at best; the 2214 is recorded
  for Q8.

## LockHS (fixed, uncommitted)

`NoStutter(NoHistoryChange(l0(self)))`: an ACTION passed as an operator
argument was evaluated eagerly by `+bind-psub` (the successor not yet
solved). Now bound by name with a closure of the caller's scope (as the
INSTANCE substitutions are since R4.3), and `+solve` solves a by-name formal
in action position (tlc2's getNextStates follows the Context binding).
Success 41/28/10 = pin. Arm `test-action-argument-solved` (pin 4/4/4; bites).

## Microbenchmarks (`%tla-ex zprobe/q0/p01–p14`)

Marginal cost per element of `ASSUME \A k \in 1..20000 : <expr>`, over the
`TRUE` baseline (≈40 µs per loop step itself):

| expr | µs/element |
|---|---|
| `k = k` | 28 (57 with a 20,000-pair constant `F` in the module) |
| `k + 1 = k + 1` | ≈280–300 |
| `<<k, k>> = <<k, k>>` | 250 |
| `{k} = {k}` | 153 |
| `[a |-> k].a = k` | 149 |
| `F[k] = k` (20,000-pair F) | 215 |
| `\E j \in {k} : TRUE` | 174 |
| `IF k > 0 THEN TRUE ELSE FALSE` | 206 |
| `Op(k)`, `Op(z) == z = z` | 193 |
| `LET y == k IN y = y` | 174 |
| `k \in 1..20000` | 278 |
| `Cardinality({k, k + 1}) = 2` | 407 |
| `{j \in {k, k + 1} : j > k} = {k + 1}` | 595 |

**New H21: every numeral literal is re-parsed on each evaluation.**
`+eval-lit` calls `(rash val.n dem)`; one parse of `'1'` costs ≈45 µs
(dojo: 20,000 parses 932 ms vs 20 ms for the bare loop). `k + 1 = k + 1`
pays two of them. tlc2 parses once.

Other readings: per-node cost grows with the environment (`k = k` 28 → 57
µs with a large constant in scope), consistent with H12/H13 (dispatch,
per-evaluation checks) and with the memo keys being built over the env.

## Partly localized

MCBakery (live `%bout` timers in a ship-only `lib/job` copy): semantic
generation 1.7 s, run-spec, environment, draw test and ASSUMEs each under
15 ms; then the INITIAL-STATE SOLVE runs past 4 minutes (tlc2: 10 s for the
whole model). The other seven are expected to be the same class; Q4 checks
each.


Which part of %config the 8 single-slice models spend their time in: a
dojo-generator step that is interrupted prints none of its `%bout` lines,
and the agent path cannot be interrupted mid-event without risking the ship
(the 2026-10-19 crash). Left to Q4 (it runs those models with per-phase
timers that complete, at a reduced size).

## Incident

2026-10-19 ~15:02: the king crashed during a `probe2.py` stage probe of
MCBakery (one %config slice ran ~57 min; probe2 had no watchdog). Fresh
pier #4 (user's choice). probe2.py now runs `examples.Watchdog`;
`guarded.sh` finds the serf by its arguments (it failed silently on the new
pier's binary name) and exits on the dojo's `interrupt`.
