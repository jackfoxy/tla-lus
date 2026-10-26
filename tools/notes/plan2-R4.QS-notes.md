# R4.QS notes — bounded slices (2026-10-25)

Plan `~/FoxyLabs/tla-lus/R4-perf-plan-r3.md`, unit QS (r14's deferred
"adaptive slice").

## Problem

A slice is `default-budget` = 256 work units, and a unit was a state
registered or a successor generated. MCInnerSerial's expansions each cost
seconds, and some cost minutes, for ~3 successors, so one Gall event ran
for ≈34 min. Behn re-fires an interrupted slice ahead of any cancel. The
2026-10-19 and 2026-10-25 king crashes both followed such events.

## Changes

1. **Candidate work** (`lib/node-eval`, `lib/check`): `rst` gains `wrk`,
   the candidate partial states `+solve-conj` threads. `+bfs-step` charges
   `wrk / 16` per expansion on top of its successors and clears it, so a
   65,536-candidate expansion fills a slice by itself. `+eval-sdef` keys its
   memo with `wrk` zeroed and adds it back on a hit, so the counter never
   splits a key. Alone this cut MCInnerSerial's slices from tens of minutes
   to 126–185 s. The rest is set-filter evaluation in the pure evaluator,
   which does not thread `rst`.
2. **Paced budget** (`lib/job` `+pace-budget`, `app/tla-lus` `pace` per
   job): the time between a job's consecutive step wakes is the length of
   the slice between them. The next budget scales toward `pace-goal` (5 s)
   when the last slice ran over 2×, doubles when under ½, and stays between
   1 and 256. A new job starts at 16. The agent state gains
   `pace=(map req-id [at=@da bud=@ud])`, dropped with the job (a stored
   state of the old shape resets, as development builds do). Arm
   `test-pace-budget`.

A fixed smaller budget was measured and rejected. On Chameneos, budget 32
gave 403 s against 334 s and 333 s at 256 (≈24 ms per extra slice).
Pacing keeps 256 wherever a slice is short.

3. **Per-slice fixed cost, found by the first census** (`logs/census-qs.txt`:
   EWD998ChanID 95 → 802 s, MCReachable 122 → 274 s, counts equal). With
   slices small, a cost paid once per slice showed: ≈13 s for EWD998ChanID
   (`%bout` in `+bfs-step`). It had two parts:
   - The liveness path built `bfs-opts` with no `acts`, so `+bfs-step`
     rebuilt the getActions decomposition at every slice (12.8 s). It now
     builds them once, as the safety path has since R2.7.4.2b.
   - `+with-cdefs`'s `~+` entry (every constant definition, evaluated) does
     not survive a slice: the per-state memo entries evict it from the
     bounded cache. `bfs-opts` now carries `cd`, the evaluated definitions,
     and `+env-of`/`+cenv-of` use `+make-env-cd:ne` with them. The liveness
     stage's environments are routed the same way.
   Per slice for EWD998ChanID: explore 13 s → 0.45 s, liveness 13 s →
   0.4 s.
4. **Pacing retuned** to tolerate a fixed per-slice cost: goal 10 s, double
   below it, scale down only above 20 s.

## Measured

MCInnerSerial through the agent (600 s wall): dojo commands answered in
6–19 s throughout (`dojo.sh`'s own floor is ≈5 s), against minutes before.
The job ended at 620 s, right at its wall (`limited time`, 160/669), and
progress lines arrived every 15–40 s. Throughput was unchanged.

The floor is now one expansion: MCInnerSerial's slowest single expansion
still runs for many minutes in one event, because expansions are atomic.

Regression 65/65 (`logs/qs-regress1.txt`).

## Gates and census (final code)

Regression 65/65 (`logs/qs-regress2.txt`); validate, scaffold-gate,
test-examples PASS. Targeted census `logs/census-qs2.txt` (16 rows) against
census-q5: every count unchanged; **EWD998ChanID 95 → 47 s, MCReachable
122 → 40 s, MCReachabilityTestAllGraphs 352 → 246 s**, MCNanoLarge 61 → 53 s,
TestGraphs 251 → 224 s; the rest within noise.
