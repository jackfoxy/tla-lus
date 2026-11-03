# R4.P0 — profiler and cost model (2026-10-09)

**Status: DONE**, for the hypotheses that can be measured off the agent
with timed experiments. H7–H9 are deferred, with reasons, to the units that
own them.

## Method

There is no committed instrumentation. A scratch `%say` generator
(`gen/tla-lus/prof.hoon`, on the ship only; a copy is in the session
scratchpad) calls the engine directly and times each experiment with
`~>  %bout`. Each experiment varies ONE parameter and holds the rest fixed,
so a cost is read off as a slope.

- Ship: `tla-zod`, vere 4.6, `--loom 33`, idle (no census or `validate.py`
  running).
- Fixed overhead of a `run-check`, parse + semantic + config of a small
  spec: about 1.0 s.

## Results

| H | experiment | measurement | verdict |
|---|---|---|---|
| — | grid spec (`x, y ∈ 0..299`, queue ≤ 89), cap 250 → 4 000 distinct | marginal 1.25 → 1.34 ms per distinct (about 0.65 ms per generated), about 790 distinct/s | per-state constant; linear when the queue is small |
| **H1/H2** | `Init == x \in 0..N`: the queue grows to N; N = 2.5k, 5k, 10k, 20k | 1.92 / 3.60 / 8.93 / 27.70 s. Fit `a + bN + cN²`: c = 5.2×10⁻⁸ s/state², b = 2.8×10⁻⁴ s/state; the fit predicts 10k→20k to within 2% | **CONFIRMED.** Per-state cost is O(queue). At 20k queued, the quadratic term is 21 of 28 s; at 100k it would be about 520 s |
| **H3** | job kernel, grid spec, budget 256 vs one slice, at 4k and 8k states | 4k: 7.47 vs 6.09 s (+46 ms/slice); 8k: 17.09 vs 11.25 s (+96 ms/slice). Per-slice cost doubles with states seen; total overhead ×4.2 for N ×2 | **CONFIRMED.** About 24 µs per seen state per slice, O(N²/budget); at 100k states about 470 s of pure persistence |
| **H5** | `+equal` of two k-sets (one reversed) | k = 10: 1.5 ms; 50: 38 ms; 100: 151 ms per call | **CONFIRMED, severe.** O(k²): `+norm-set` dedups with a `lien` over the rest, and `+equal` re-normalizes both operands on every call |
| **H6** | `state-fp` of a state holding two ints and a k-set | k = 2: 0.21 ms (15 bytes); 20: 3.3 ms (105 bytes); 100: 66 ms (505 bytes) | **CONFIRMED, for a different reason than stated.** The `weld` chain is linear (each left operand is one element); the quadratic part is `+fp-input`'s `(normalize v)`, which is H5. The per-byte `map` lookup is a constant factor |
| **H4** | `SimplifiedFastPaxos/Paxos`, cap 30, four config variants | full 143 s (32 distinct / 118 generated); without `PaxosTypeOK` 19.9 s; without SYMMETRY 132.9 s; without both 13.2 s | **CONFIRMED as Paxos's bottleneck, with the mechanism corrected.** `Quorums` is a cfg constant here, not a definition. The cost is `PaxosTypeOK`: `messages \subseteq Message`, where `Message` (about 240 records) is a zero-arity definition re-built per state (H4), normalized in O(n²) (H5), and checked element by element. That is about 3.9 s per state, 86% of the run. tlc2: 1,207 states in 4.2 s |
| — | Paxos without `PaxosTypeOK` | 0.17–0.24 s per generated state; states carry a `messages` set of records | per-state set work (H5 in successor evaluation and fingerprinting) |
| H7 | `env-of` / `get-actions` per state | not separable without an instrumented build | **deferred to R4.P1**: measure after H1–H3, when it can show |
| H8 | `seen` stores whole states | memory, not time | **deferred to R4.P6** (measure RSS per 10k states there) |
| H9 | liveness builds the whole graph | needs a liveness workload | **deferred to R4.P7** |

## The cost model, in one line

`time ≈ fixed (about 1 s) + N × (per-state work, dominated by set
normalization: O(k²) in the size k of any set in the state or the
invariant) + c₁·Σqueue (H1/H2) + c₂·N²/budget (H3)`.

For the Examples corpus the set-size term (H5) is the largest today. Small
models with record-set states (Paxos, MCChangRoberts-like) are slow at very
small N, and no asymptotic fix helps them. H1–H3 decide whether anything
past about 20k states finishes at all.

## Targets (T1–T4), revised

- **T1** (rate at 100k within ±20% of the rate at 10k) cannot hold until
  H1, H2 and H3 are fixed. Keep it as R4.P1/P2's exit test.
- **T2** (≥ 2 000 distinct/s on `queue`; no small model below 200/s): the
  per-state constant today is about 790/s on the simplest grid and
  0.03–0.2/s on Paxos. 2 000/s on the simplest workloads needs about 2.5×
  on the constant. The "no small model below 200/s" clause is unreachable
  until H5 is linear. **Revised:** keep 2 000/s as the goal for the grid
  class; for the small-model clause, measure again after R4.P4 (H5) before
  setting a number.
- **T3, T4:** unchanged (unmeasured here).

## Reordering this implies (fed into R4.P1–P4)

1. **R4.P4 (H5, canonical values) is worth as much as R4.P1 and moves up
   beside it.** Sort-then-adjacent-dedup is O(k log k) if `+vlth` is
   consistent with `+equal-norm` (R3.2a says it is). Store values
   normalized, so `+equal` and `+fp-input` stop re-normalizing. That fixes
   H5 and H6 together.
2. **R4.P1 (H1/H2):** the queue as an O(1) deque plus a length counter.
3. **R4.P2 (H3):** stop re-jamming `seen` per slice.
4. **R4.P3 (H4):** precompute zero-arity constant-level definitions.
   Paxos's `Message` then costs nothing per state, and with R4.P4 its
   `\subseteq` becomes linear.

## R4.P0b — bottleneck of each timed-out Example

Method: `gen/tla-lus/probe.hoon` (scratch, ship-only) drives the job kernel
off the agent, at 256 units per slice and at most 60 slices, answering Clay
reads by scry and printing each slice's time and stage. A guard sends ONE
`C-c` at 180 s or 1.5 GB, and the trace names the hot arm. The full verdicts
are in each entry's `bottleneck` field in `desk/test-data/blackbox/timed-out.json`.

| model | where the time goes | owner |
|---|---|---|
| CoffeeCan100Beans | `%config`: forces `Can` (10,201 records); `+norm-set` O(n²) | R4.P4 (H5) |
| CoffeeCan1000Beans, 3000Beans | **not perf**: fail in 6 s with `set with too many elements (>1,000,000)`. The port materializes `Can`; tlc2 enumerates it lazily | R4.2i (lazy record-set membership) |
| GameOfLife | `%config` 170 s in `+norm-set` | R4.P4 (H5) |
| EWD840_anim | `+norm-set` right after parse | R4.P4 (H5) |
| Paxos | `PaxosTypeOK`: `Message` re-built and normalized per state | R4.P3 (H4) + R4.P4 (H5) |
| ElevatorSafetyMedium | init: 19,683 generated in 112 s, then `+solve-each`'s `(weld out p.r)` | **R4.P1 (H10, new)** |
| ElevatorSafetyLarge | `load-kont` (`cue` + `;;`) on the continuation `%config` built | R4.P2 (H3) |
| PaxosCommit | enumeration: `enum-next` `%elems` does `lent` + `snag` per element; `odo-build` normalizes each record | **R4.P1 (H11, new)** + R4.P4 |
| ACP_SB_TLC | steady 2.3 s per slice, about 38 distinct/s, about 9 ms per generated state | per-state constant; re-measure after R4.P4 |
| bosco | first explore slice > 170 s; the trace was lost in dojo frames | re-probe at budget 1 after R4.P1/P4 |
| MCChangRoberts | memory runaway, about 80 MB/s, on a 137-state model | engine bug, R4.2q; probe only at budget 1 under a 1 GB cap |

**New hypotheses, both quadratic:**
- **H10:** `+solve-each` (node-eval.hoon:2165), `+solve-disj` (:2176) and
  the rows solver (:2203) accumulate with `(weld out p.r)`, which is
  O(n²) in the number of states they produce.
- **H11:** `enum-next`'s `%elems` arm (value.hoon:1097-1099) does
  `(lent es.cur)` and `(snag i.cur es.cur)` per element, so enumerating an
  explicit set is O(n²).

Both move into R4.P1, with H1/H2.

**Weight of evidence:** H5 (set normalization) is the bottleneck of 5 of the
12, more than any asymptotic search cost. R4.P4 should follow R4.P1/P2
directly.
