# R4.Q9 notes — re-measure (2026-11-02)

Plan `~/FoxyLabs/tla-lus/R4-perf-plan-r3.md`, unit Q9. Approved by the
user on 2026-11-02. Code at `df259aa7` (R4.QW).

## Runs

`/mnt/mars/piers/tla-zod-tools/q9-census.sh`:

- **Small:** the 123 small models outside `timed-out.json`, `--wall 900`
  → `logs/census-q9-small.txt`.
- **Timed-out small:** GameOfLife, SimplifiedFastPaxos/Paxos and btree,
  one by one. **MCChangRoberts was not run**: it is the known runaway that
  crashed the ship twice.
- **Large smoke:** `--size large --include-timed-out --budget 1000
  --wall 900` → `logs/census-q9-large.txt`.
- MCInnerSerial's clause-3 result is QW's run on this commit (3,800 s
  wall, success = pin in 2,393 s).

Incident: about 2 h in (2026-11-02 ~09:15), during Disruptor_SPMC's
liveness phase, the **king wedged**. It spun in user space with no
syscalls and no I/O, the serf idled, and conn stopped answering. The
runner's watchdog then SIGINTed the idle serf 41 times, and the runner died
on a conn timeout. Snapshot backed up (`tla-zod-chk-backup-2026-11-02-0917`).
The user chose a normal restart: the king took SIGKILL and the ship
replayed cleanly. The census resumed from row 14, and Disruptor_SPMC then
succeeded in 745 s.

## Clause 2 (127 small)

| class | n | |
|---|---|---|
| success = pin | 93 | the classifier's 89 "agree" + PrisonerLightUnknown, SpanTree, kvstore, EWD840, whose depth equals the PIN (the manifest's `stateDepth` is the `-workers auto` one; R4.0c, the pin wins) |
| **wrong answer** | **1** | **ElevatorSafetySmall: counts = pin (4,122/14,296), depth 32 against 36 → R4.2au** |
| approved refusal | 2 | SmokeEWD998 (`TLCGet("duration")`, R4.2h), EWD998ChanTrace (`ndJsonDeserialize`, R4.2f read half) |
| too slow (900 s) | 30 | below |
| not run | 1 | MCChangRoberts (runaway) |

At R4.Q's start (Q0) the time-bound list was 51 rows plus btree,
CoffeeCan1000Beans and MCQuicksort. Completed since Q0 at a 900 s wall (this
census): CarTalkPuzzle Model_2, Disruptor_SPMC, MCFindHighest, MCMajority,
MCReachabilityTestAllGraphs, ReadersWriters, SingleLaneBridge,
SchedulingAllocator, MC_sums_even, plus Q0b's 12 and Q8's.

The 30, by what each still needs (distinct at 900 s against the manifest):

| class | models |
|---|---|
| startup (one long `%config` slice, 0 states) | MCBakery, CarTalkPuzzle Model_1, TransitiveClosure, MCBinarySearch, YoYoAllGraphs |
| explored completely, out of time in liveness | CoffeeCan1000Beans, Disruptor_MPMC_liveliness, GameOfLife, ElevatorLivenessMedium, TokenRing, nbacg_guer01 |
| near (≤ 2×) | MCPaxosTiny (1.0×), MCVoting (1.1×), bcastByz (1.2×), SimplifiedFastPaxos/Paxos (1.3×), AllocatorImplementation (1.7×) |
| 2–10× | MCQuicksort (2.8×), MCCRDT (3.5×), Disruptor_MPMC (3.7×) |
| 10–100× | braf (10×), MCLamportMutex (16×), FastPaxos (20×), MCNanoMedium (25×), btree (26×), MultiPaxos_MC_small (34×) |
| > 100× | TLCSailfish1 (118×) |
| no manifest count | MCCheckpointCoordinationFailure, SlidingPuzzles ×2, SpanTreeRandom |

## R4.2au — ElevatorSafetySmall's transition graph differs (WRONG ANSWER)

The port reports 4,122 distinct / 14,296 generated (= pin) and depth 32;
the pin reports 36. From tlc2's own state graph (`-dump dot`), a BFS from
the 64 initial states gives max depth **36**. So 36 is right, and the
port's graph has shorter paths: some successor edges differ, while the
counts coincide. It is not model-value tie order (`tlc-value-order`): tlc2
gives 36 under `Elevator = {e2, e1}`, under `Person = {p2, p1}`, and with
every `e2` identifier renamed out of the spec. It has been there since at
least R4.2v (census-r42v: depth 32). ElevatorLivenessMedium is the same
spec, and its liveness verdict depends on the edges. Not yet localized; the
port has no state-graph dump.

## Clause 3 (31 large)

30/31 under the smoke budget. MCInnerSerial is too slow at 900 s and
succeeds at the ≈63-minute per-model wall (r3 decision 1, option A) →
**31/31** with that wall.

## Tier 3 (`tools/tier3-report.py`, `logs/tier3-q9.json`)

Against the R2 baseline (vere 4.6, 2026-09-02): enum −62%, eval −59%,
ex-coffeecan −17%, ex-gameoflife −32%, fp −73%, live −72%, queue −40%.
Report only, no gate.

## R4.Qb — the 11 near/explored rows at `--wall 3600` (2026-11-03)

Plan r16 decision 2: A, a recorded R4 fallback, plus this census for the
number. Code at `2161b178` (R4.2au), `logs/census-qb.txt`.

| model | result | vs manifest |
|---|---|---|
| MCPaxosTiny | **success 1,266 s** | 3,921 / 23,563 / 17 = manifest |
| MCVoting | **success 1,198 s** | 6,752 / 41,017 / 16 = manifest |
| SimplifiedFastPaxos/Paxos | **success 1,668 s** | 1,207 / 13,290 / 22 = manifest |
| Disruptor_MPMC_liveliness | **success 1,070 s** | 14,365 / 44,581 / 61 = manifest |
| ElevatorLivenessMedium | **success 1,899 s** | 4,122 / 14,296 / 36 = manifest (depth right since R4.2au) |
| TokenRing | **success 1,428 s** | 46,656 / 248,832 / 1 = manifest |
| nbacg_guer01 | **success 934 s** | 24,922 / 159,538 / 16 = manifest |
| bcastByz | limited time 3,605 s | explored (14,424 / 227,344 = manifest), out of time in liveness |
| AllocatorImplementation | limited time 3,627 s | explored (17,701 / 64,414 = manifest), out of time in liveness |
| CoffeeCan1000Beans | limited time 3,607 s | 501,500 distinct (= manifest), 1.70 M of 2.00 M generated |
| GameOfLife | limited time 3,621 s | 65,536 distinct (= manifest), 73,551 of 131,072 generated |

(`--only bcastByz/bcastByz` also re-ran bcastByzNoBcast: success, 30.6 s,
as before.)

**7 of the 11 complete within an hour**, every one equal to the
manifest. The 4 others have found every distinct state and run out of time
in liveness or in the last expansions.

## Clause 2 at the R4.Q close: the recorded fallback (plan r16 decision 2, A)

- 93 small models report the pin's outcome at a 900 s wall, and **7 more
  at 3,600 s** (above).
- 2 end in approved refusals (SmokeEWD998, EWD998ChanTrace).
- **24 remain time-bound at an hour**, R4's recorded fallback, with each
  row's class and gap as listed under *Clause 2* above:
  - startup class: MCBakery, CarTalkPuzzle Model_1, TransitiveClosure,
    MCBinarySearch, YoYoAllGraphs;
  - explored but out of time: bcastByz, AllocatorImplementation,
    CoffeeCan1000Beans, GameOfLife;
  - 2–10×: MCQuicksort, MCCRDT, Disruptor_MPMC;
  - 10–100×: braf, MCLamportMutex, FastPaxos, MCNanoMedium, btree,
    MultiPaxos_MC_small;
  - over 100×: TLCSailfish1;
  - no manifest count: MCCheckpointCoordinationFailure, SlidingPuzzles ×2,
    SpanTreeRandom;
  - and MCChangRoberts, not run (the known runaway).
