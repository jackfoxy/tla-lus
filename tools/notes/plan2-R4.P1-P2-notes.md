# R4.P1 + R4.P2 — search asymptotics, persistence, slice liveness (2026-10-09)

**Status: DONE**, pending the user's check-in (tests and plan review).
Measurements come from the R4.P0 scratch generator (`gen/tla-lus/prof.hoon`,
ship-only) unless stated.

## R4.P1 — every O(n)-per-state site R4.P0/P0b found

| H | site | fix | evidence |
|---|---|---|---|
| H1 | `bfs-cursor` `queue=(list @t)`, `(snoc queue fp)` per enqueue | `+$  fifo  [front back len]`; `+fi-put` O(1), `+fi-pop` O(1) amortized; BFS order unchanged | see below |
| H2 | `(lent queue.cur)` in `+run-stats-at` / `+with-run` / outcomes, **per registered state** (11 sites, plus 2 in `lib/job`) | `len.queue.cur`, O(1) | |
| — (found here) | `inits.cur` built with `(snoc inits.cur fp)` per initial state | prepend; the 4 readers (`graph` exports, the `%live` product) `flop` it once | init-heavy specs (Elevator: 19,683 inits) |
| H10 | `+solve-each`, `+solve-disj`, the `\E` rows solver: `(weld out p.r)` per partial result | accumulate reversed with `(weld (flop p.r) out)`, flop once | |
| H11 | `enum-next` `%elems`: `(lent es)` + `(snag i es)` per element | consume the list (`es` = the rest); `+cur-bound` is only called on fresh cursors, so its count is unchanged | |

**Asymptotic result:**
- Initial-state registration (`Init == x \in 0..N`): before, 1.92 / 3.60 /
  8.93 / 27.70 s at N = 2.5k / 5k / 10k / 20k. After, 1.84 / 2.84 / 5.58 /
  13.38 s.
- The grid search from 10k to 40k distinct is LINEAR: 21.1 / 43.9 / 88.5 s,
  with a marginal 2.28 → 2.23 ms per state. **T1 holds on this workload.**
- A residual rise remains on the init-only workload (marginal 0.40 → 0.78
  ms per state from 2.5k to 20k), much smaller than before. It is not yet
  attributed.

**Correctness:** byte-identical behaviour. All 19 search-engine shards were
green after the change: mc 106, safety-gen 10, dfid 23, sim-diff 82,
generate-diff 30, liveness-message 10, job 126, trace 8, stream 48, tlcmod
48, core-eval 21, **perf 5 (the tier-3 deterministic work profiles)**, bags
49, neval-mc 5, neval-action 6, stdops-diff 9, clay-load 36, blackbox 40,
app 41.

**Constant factor, A/B:** the pre-R4.P1 libraries against the current ones,
deployed alternately, three timed grid runs each (4k distinct), load average
2.5–4:

| build | runs |
|---|---|
| old | 8.65 / 6.78 / 6.76 s, then 7.78 / 6.55 / 6.79 s |
| new | 6.17 / 6.24 / 6.17 s, then 6.42 / 6.66 / 6.34 s |

New is 5–9% faster, with no regression. Two things inflate single readings:
- the first run after a rebuild is slower (warm-up), which is the 8.65 and
  7.78;
- machine load: the 2.1 ms-per-state readings were taken at load average
  4–7.

**Timing rule from here on:** discard the first run after a build, and
report the load average with every number.

## R4.P2 — persistence (H3) and slice liveness

### H3: the continuation is no longer jammed, cued and clammed per slice

Measured at 8.1k states (a 200 KB jam): cue 15 ms, `;;` clam **140 ms**,
jam 16 ms, met 0.2 ms per slice. The clam over the recursive `kont` mold
was 82%.

- `cont=(unit [%1 k=*])`; `k` is `[kont-tag kont]`, stored as is.
  `kont-tag` is `^~((sham -:!>(*kont)))`, a compile-time hash of the
  `kont` TYPE.
- `+load-kont`: a cell with the matching tag is loaded through `!<` (one
  type-nest check, no walk of the value). A mismatched tag means another
  engine version wrote it; it crashes, and every caller already turns that
  into the restart notice (the Work Unit 7.7 contract). An ATOM is a
  legacy jammed continuation, or hostile input, and takes the old checked
  `cue` + `;;` path, so the fuzz contract (R1.2.5) is unchanged.
- `+noun-over` still measures the jam size, so the 16 MB bound means what
  it meant.

Result: grid, 8k states, one slice vs 63 slices of 256: **11.70 vs 11.10
s**. Before: 11.25 vs 17.09 s (+5.84 s). Persistence overhead is now within
noise. New arms in `tests/lib/job.hoon`: `test-kont-round-trip`,
`test-kont-foreign-tag-restarts`, `test-kont-legacy-jam-loads`. Shards
green: job 129, fuzz 14, app, clay-load, blackbox, liveness-message,
sim-diff, dfid, generate-diff, perf.

### Slice liveness: agent state `%1`, numbered wakes, the sweep

R4.0 measured that an interrupted event can consume a job's only behn wake
and leave it `running` forever.

- `state-1 = [%1 jobs arms=(map req-id @ud) sweep=(unit @da)]`; `on-load`
  converts `%0`.
- A step wake's wire carries the job's current wake number
  (`/job/<id>/step/<n>`). A wake with any other number is stale and
  ignored, so re-arming can never fork a second step chain. A numberless
  wire (scheduled before this change) is honoured.
- `on-load` re-arms every running job (except `%modules` jobs, which their
  `%writ`s resume) and restarts the sweep.
- The sweep (`/sweep/<@da>`, every `~m1` while any job runs) re-arms every
  running job. A lost wake therefore costs at most a minute, never the
  job.
- `/x/version` is `[1 1]` (state `%1`); scaffold gate 6 checks `%1`;
  `api.md` is updated.
- Arms in `tests/app/tla-lus.hoon`: `test-stale-wake-ignored`,
  `test-on-load-migrates-and-rearms`, `test-sweep-rearms`. Updated for the
  new design: the submit card count (2 → 3, plus the sweep), the numbered
  wire shape, `[api-version 1]`, and the two save/load tests, which now
  compare jobs (the wake numbers advance on load by design). app: 44 green.
- Live: the `%0` → `%1` migration ran on `tla-zod` without loss. DieHard,
  MissionariesAndCannibals and TCommit agree through the runner. A SIGINT
  to a live ACP_SB_TLC job: it kept progressing (that wake was re-fired,
  not lost), and a `%cancel` landed at once.

**Not done, by design:** "a failed slice is not re-run unchanged" (r7's
item 2). An aborted event commits nothing, so no state can record that a
slice was attempted, and a time-based guess cannot tell an interrupted
slice from a ship that was down. It is covered instead by:
- R4.2y: a Hoon crash is caught by `mule` and the job is sealed;
- the request's `max-time`, checked before any work;
- bounded slices, now that H1–H3/H10/H11 are linear, so a `%cancel` lands
  between slices.

The remaining exposure is the unbounded single-step stages (`%parse`,
`%config`: semantic generation, init solving, H5 normalization). That is
R4.P4's to shrink.

## Effect on the timed-out models

To be re-run at the R4.P close (tracker line). R4.P1/P2 target 3 of the
12: ElevatorSafetyMedium (H10), ElevatorSafetyLarge (H3), PaxosCommit (H11).
The other 9 wait on H5 (R4.P4), H4 (R4.P3) or correctness rows.
