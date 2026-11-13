# Performance: what finishes, and how fast against TLC

Measured 2026-11-05 to 11-12, at R4's acceptance. Every number here comes
from a file in the repo. How to reproduce the numbers is at the end.

## In short

- **Speed.** On models with thousands to tens of thousands of states,
  `%tla-lus` is roughly **100–370× slower than tlc2 running single-threaded**
  on the same machine: about 7–120 distinct states per second against tlc2's
  10,000–20,000. The gap grows with the model, to an estimated 400–1,600× on
  the largest small models. A start-up-dominated model is about 10× slower.
- **What finishes.** Of the 127 Examples models CI calls *small*, 101 finish
  within an hour with the pin's answer. 2 never will, by design. 23 need
  more than an hour. One, MCChangRoberts, runs away in memory. Of the 31
  *large* models, only a 1,000-state smoke run was ever done.
- **The front end** (parse, semantic analysis, level checking) takes a median
  of 5.6 s per module through the agent; 90% of modules take under 16 s.

## Method

| | |
|---|---|
| Machine | Intel Core i7-3770K, 3.50 GHz, 8 threads |
| `%tla-lus` | a fake ship on vere 4.6 with `--loom 33`, driven through the agent's public wire by `tools/examples.py` (R4 code at acceptance) |
| tlc2 | the pinned `tla2tools.jar` (`tlaplus@4ba7d8811`) on OpenJDK 11, run as the goldens run it: `-workers 1 -fp 0 -seed 0` |
| Port timings | the R4.5.3 runner pass, `desk/test-data/blackbox/r4-runner/*.txt` (`secs` per model) |
| tlc2 timings | `desk/test-data/blackbox/tlc2-timings.txt` (`tools/tlc2-timings.py`) |
| Model data | `desk/test-data/blackbox/models.json` (the manifests' recorded state counts and CI runtimes) |

Both clocks are wall time for a whole run. tlc2's includes JVM start-up
(about a second). The port's includes the submit and the runner's polling,
which checks every 10 seconds. So for runs under about a minute, both
figures overstate the work.

Upstream CI's own recorded runtimes (`runtime` in the manifests) are not a
fair yardstick. They come from `-workers auto` on CI's machines, are rounded
to whole seconds, and include JVM start-up. Against them the median ratio
looks like 23×.

## Speed against tlc2, same machine

| model | distinct states | tlc2 | `%tla-lus` | slower by |
|---|---|---|---|---|
| HourClock | 12 | 0.9 s | 10 s | 11× (start-up) |
| CoffeeCan100Beans | 5,150 | 2.5 s | 117 s | 47× |
| ElevatorSafetySmall | 4,122 | 1.8 s | 190 s | 106× |
| Chameneos | 34,534 | 3.0 s | 403 s | 134× |
| nbacg_guer01 (liveness) | 24,922 | 7.2 s | 1,030 s | 143× |
| ACP_SB_TLC | 54,944 | 3.0 s | 449 s | 150× |
| MCVoting | 6,752 | 5.9 s | 1,010 s | 171× |
| Disruptor_SPMC | 8,496 | 3.0 s | 597 s | 199× |
| MCDieHardest (a violation) | 11,566 | 2.0 s | 404 s | 202× |
| MCPaxosTiny | 3,921 | 4.8 s | 980 s | 204× |
| TokenRing (liveness) | 46,656 | 4.1 s | 1,508 s | 368× |
| MCInnerSerial (large) | 195 | 656 s | 2,963 s | 4.5× |

MCInnerSerial is the outlier: tlc2 itself takes ten minutes on it, because
each state's successors range over large sets of relations, and the port's
lazy evaluation of those sets (R4.QW) narrows the gap.

Models that did not finish within the hour, with the port's time projected
at the rate it reached (a straight line, so probably optimistic):

| model | distinct states | tlc2 | `%tla-lus`, projected | slower by |
|---|---|---|---|---|
| MCLamportMutex | 724,274 | 24.9 s | ≈ 3.3 h | ≈ 480× |
| FastPaxos | 25,617 | 49.2 s | ≈ 5.5 h | ≈ 400× |
| btree | 374,727 | 42.7 s | ≈ 6.0 h | ≈ 500× |
| TLCSailfish1 | 109,604 | 67.2 s | ≈ 31 h | ≈ 1,600× |

The port is a tree-walking evaluator over Hoon nouns inside a Gall agent. It
checks in bounded slices (256 work units per Behn wake) so the ship stays
responsive, and it persists the search between slices. tlc2 is a JIT-compiled
Java program with mutable hash tables. R4's performance work (`R4-perf-plan`,
units R4.P and R4.Q) took the tier-3 workloads 17–73% faster than the R2
baseline. It did not change this order of magnitude.

## Does every model finish, given enough time?

Not every one.

**Small models (127 in CI's split; recorded TLC runtime 30 s or less).**

| | n | |
|---|---|---|
| finish within an hour with the pin's outcome | 101 | 94 within 900 s, 7 more within 3,600 s |
| never finish: refused by design | 2 | SmokeEWD998 reads the wall clock (`TLCGet("duration")`); EWD998ChanTrace reads a file (`ndJsonDeserialize`). Both are approved differences |
| runaway | 1 | MCChangRoberts: tlc2 checks it in 1 s (137 states); the port's memory grew about 80 MB/s and crashed the ship's worker process in October 2026. Not re-measured since the R4 performance work |
| need more than an hour | 23 | below |

The 23, by what they still need (the one-hour run of R4.5.3):

| what remains | models | projected at the measured rate |
|---|---|---|
| every state found; the liveness check did not finish | bcastByz, AllocatorImplementation, CoffeeCan1000Beans, GameOfLife | not measured; very likely to finish |
| exploring | MCQuicksort, MCCRDT, Disruptor_MPMC | 0.7–1 h |
| | BufferedRandomAccessFile | 2.5 h |
| | MCLamportMutex | 3.3 h |
| | FastPaxos | 5.5 h |
| | btree | 6 h |
| | MCNanoMedium | 8 h |
| | MultiPaxos_MC_small | 11 h |
| | TLCSailfish1 | 31 h |
| still computing the initial states after 17 minutes | MCBakery (655,200 initial states), CarTalkPuzzle Model_1, TransitiveClosure, MCBinarySearch, YoYoAllGraphs | no rate to project from |
| no state count in the manifest | MCCheckpointCoordinationFailure, SlidingPuzzles, SlidingPuzzles_anim, SpanTreeRandom | unknown size |

**Large models (31; recorded runtime over 30 s, or unknown).** Acceptance
asked only for a smoke run: 1,000 distinct states with no error. All 31
passed. Two of them finish outright: MCReachable and MCInnerSerial. None of
the others has been run to the end. CI records runtimes of up to 7 h 16 m
for them (MCKVSSafetyLarge), with several workers; at this port's speed that
is weeks to months. Most manifests record no state count for them, so it is
not known which would also reach the port's bound below.

**The bound on one check.** A check carries its search between slices as a
persisted continuation, capped at 256 MB. That is about 8–10 million
distinct states for small states. Past it the check ends `%limited %noun`
with its statistics. Large states fill the 8 GiB loom first: GameOfLife-sized
states fit about 2 million. Runs past about a million states have not been
measured (`users-guide.md`, *Runtime envelope*).

## The front end

Through the agent's public wire, on all 373 Examples modules, imports
included (the R4.4 census, `parse-census-unicode.txt`):

| | |
|---|---|
| median | 5.6 s |
| 90th percentile | 16 s |
| 99th percentile | 27 s |
| slowest | `tcp_proof` (5,661 lines), about 90 s |

Unicode spellings cost nothing measurable. SANY's own time on the same
modules was not measured.

## Reproduce

```
tools/r4-examples-run.sh OUTDIR                   # the port, about a day on a live ship
tools/tlc2-timings.py OUT MCVoting.cfg ...        # tlc2, minutes
tools/examples.py --parse --unicode               # the front end
```

`tools/tier3-report.py` reports the port against itself, on the tier-3
workloads (`testing.md`, *Tier 3*).
