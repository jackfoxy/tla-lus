# R4.P8: runtime envelope (2026-10-12)

**Status: DONE (measured, documented in `users-guide.md` §Runtime
envelope), plus one fix found on the way.** Two decisions are proposed for
the R4.P close.

## Measured

| | result |
|---|---|
| loom | `--loom 33` (8 GiB), as already required since R4.0 |
| grid, 90,000 distinct, one event (scratch profiler) | 127 s (1.41 ms/state; R4.P1: 2.2), serf RSS 178 → 207 MB |
| GameOfLife through the runner, 300 s | 34,048 distinct (R4.P5: 29,952), peak RSS 412 MB (65,536 initial states held) |
| visited-set jam | grid 25 B/state (491 KB at 20k, 2.28 MB at 90k); GameOfLife 30 B/state |
| Gall turn | one slice = `default-budget` 256 units: about 0.4 s on the grid, 2–3 s on GameOfLife |

1M states was NOT run. The job path cannot reach it: the continuation
bound below stops a check first, at about 500–650k states. Extrapolating
the RSS (about 3.6 KB per GameOfLife state with everything held), 1M such
states would need about 3.6 GB, which is inside the 8 GiB loom.

## Found and fixed: the continuation bound cost O(state space) per slice

`+noun-over` jams the whole continuation to compare its size with
`max-noun-bytes` (16 MB), on EVERY slice. One jam of the visited set costs
52–78 ms at 20k states and **372–527 ms at 90k**, which is more than a
slice's own work at that size. (R4.P2 removed the per-slice jam for
persistence but kept this one for the bound.)

`+noun-due` measures only when the slice's growing count (distinct states
for BFS and DFID, product nodes for the liveness product) crosses one of
16 log-spaced checkpoints per doubling: every change below 32, then about
every 4.4% of growth. The bound is still enforced, at most one checkpoint
late.
- New arm: `tests/lib/job` `test-noun-due-checkpoints` (its expectations
  were checked against a Python model of the bucket rule).
- job 130, app 44, blackbox 40, dfid 23 and fuzz 14 are green.
- GameOfLife at 300 s: 29,952 → 34,048 (+14%).

## Proposed decisions (R4.P close)

1. **Raise `max-noun-bytes`.** It was set when the continuation was jammed
   per slice (R1), to bound that cost. Since R4.P2 (no per-slice jam) and
   R4.P8 (amortized measurement), it bounds only loom growth, and the loom
   has 8 GiB with measured use under 0.5 GiB. 256 MB would admit about 10M
   small states, and memory, not this bound, would set the envelope.
2. **Make the slice adaptive (optional).** A fixed 256 units gives turns
   from 0.4 s to 2–3 s depending on the spec. The elapsed `now` between a
   job's consecutive wakes could scale the budget toward a target turn
   (say 0.5 s). Nothing inside an event can read the clock, so this is the
   only signal. It is a port-only behaviour, with no oracle.
