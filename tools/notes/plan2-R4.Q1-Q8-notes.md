# R4.Q1 + R4.Q8 notes (2026-10-24)

## Q1 — literals and dispatch

- H21: numeral literals were re-parsed with `rash` on every evaluation;
  `+fast-dec` is a byte loop (`eval-lit`). Per construct 1.4–3×.
- `+node-op` answered by a `^~` module set first (`node-op-modules`);
  every user operator call used to test all forty keys.
- Targeted census `logs/census-q1.txt` (14 rows): counts unchanged; model-level
  gains small (TestGraphs 482→336 s, EWD998ChanID 133→95, Chameneos 413→335,
  ACP_NB_TLC 591→503, the rest 1–5%). Model time is elsewhere.
- `tools/gen-stdops-tests.py` split stdops.hoon on `++  node-op`, which the
  new `++  node-op-modules` arm matched first; it now splits on the arm line.

## Q8 — liveness phase

SimpleAllocator: safety ≈10 s of 348 s; the rest is three temporal properties.

1. `+enabled-eval` / `+act-eval` memoized (`~+`) per leaf and state(s):
   ENABLED depends on s0 alone and was re-solved per edge and per
   OrderOfSolution. 348 → 225 s.
2. The product build re-ran each state's successor solve (`+succ-fps`).
   On a liveness graph build the BFS now records each in-model transition's
   successor keys (`succ` in `bfs-cursor`; `!hkey` runs; deduplicated,
   first-occurrence order; constraint-pruned transitions excluded), and
   `+product-step` reads them. 225 → 173 s.
3. Left: `+node-edges` ≈42 of ≈50 s per property, evaluating fairness action
   leaves `<A>_v` on every edge — general evaluator cost.

Targeted census `logs/census-q8.txt` (12 rows, `--wall 900`), against
census-q0b / census-q1:

| model | before | after |
|---|---|---|
| Disruptor_SPMC | limited time 1034 s (8496 distinct) | **success 908 s** = manifest |
| SchedulingAllocator | limited time 914 s (1690) | **success 552 s** = manifest |
| SimpleAllocator | success 348 s | success 179 s |
| ACP_NB_TLC | success 503 s | success 277 s |
| MCLiveWriteThroughCache | success 783 s | success 652 s |
| Chameneos | success 335 s | success 335 s (no liveness) |
| GameOfLife, ElevatorLivenessMedium, ReadersWriters, SingleLaneBridge, TokenRing, nbacg_guer01 | limited time | limited time (same counts; liveness phase) |

Every count unchanged. Complete at `--wall 900`: 12 → 14.

Regression 65/65 (`logs/q8-regress2.txt`); validate, scaffold-gate,
test-examples PASS.
