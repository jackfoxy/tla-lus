# R4.P9: tier-3 refresh (2026-10-12)

**Status: DONE (report written; gate decision recorded: still report-only,
pending the fresh-boot leg).**

## Examples-derived workloads (fixes R2.8.1b's recorded limitation)

| workload | source (tlaplus-Examples@47b0e2cc0, MIT) | engine | profile | warm median |
|---|---|---|---|---|
| `ex-coffeecan` | CoffeeCan, MaxBeanCount = 15, all four PROPERTIES + TypeInvariant | liveness | `1 452 135 0 1` | 3,718 ms |
| `ex-gameoflife` | GameOfLife, N = 2, TypeOK | safety | `32 16 0 1 0 0 0 0` | 2,750 ms |

R2.8.1b's `live` workload (12 states) was "too small to be a benchmark".
`ex-coffeecan` exercises the 8.2–8.6 engine over 4 OOS and 135 states.
Module bodies are upstream's, unchanged, with a header comment naming the
source.

## The R2 workloads after R4.P

Same work profiles (asserted; byte-identical). Time against the R2.8.1a
baseline (vere 4.6):

| workload | R2.8.1a median | R4.P9 warm median | |
|---|---|---|---|
| queue | 2,136 ms | 1,242 ms | ×1.7 |
| live | 1,106 ms | 302 ms | ×3.7 |
| fp | 2,677 ms | 746 ms | ×3.6 |
| eval | 1,876 ms | 785 ms | ×2.4 |
| enum | 1,909 ms | 776 ms | ×2.5 |

## Noise (R2.8.1a's criterion)

Warm leg, 5 runs, load average about 1.5. The median workload is `eval`,
±5.3%. Every workload is under ±8%, and `ex-coffeecan` is ±1.9%. The
run-to-run criterion PASSES on the warm leg. R2.8.1a FAILED on the
FRESH-BOOT leg (15.6%), and that leg and the rebuild delta were not re-run:
each needs 5 ship restarts. So the gate decision is unchanged:
**report-only**. Re-running the fresh-boot leg is the precondition for a
gate (a decision for the R4.P close).

`tools/tier3-noise.py`: its `took` regex did not match hyphenated workload
names; fixed.

## T4 ratio (reported, no target)

tlc2 `-workers 1` on the same workload files takes 1.0–1.25 s each, almost
all of it JVM start-up, so the small workloads do not measure throughput.
The meaningful points are larger models:
- CoffeeCan100Beans: 786 s through the port (R4.P7) against 5 s for tlc2
  (manifest, CI with `-workers auto`): about ×150.
- GameOfLife N = 4 does not finish in 900 s; tlc2 takes 5 s.

## Found: GameOfLife's cost is a function definition re-materialized per reference

The N = 3 version took 166 s for 512 states, about 160 ms per successor,
with or without TypeOK. `sc[<<x, y>> \in (0..N+1) \X (0..N+1)] == …` is a
state-dependent function definition. `score(p)` references it twice per
cell, about 18 times per state, and each reference materializes all
(N+2)² points. tlc2 builds a lazy `FcnLambdaValue` and applies it at the 8
neighbour points only. Two candidate fixes, for the R4.P close:
1. per-state memo of arity-0 definitions (pure ones, as R4.P3's rule);
2. lazy function values for `f[x \in S] == e` (the tlc2 shape).
