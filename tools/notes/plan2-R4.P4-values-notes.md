# R4.P4 — canonical values: H5 made O(n log n) (2026-10-09)

**Status: DONE**, pending the user's check-in.

## What was quadratic, and the fix (`lib/value.hoon`)

| site | before | after |
|---|---|---|
| `+equal` / `+equal-norm` | pairwise: `+elems-equal` / `+fcn-equal` / `+rec-equal`, nested `levy`×`lien`, and `+equal` normalized both sides on every call | **`+ekey`, an exact equality key**: set-likes → the key SET of their elements; fcn-likes (function, tuple, record) → the key SET of their `[d r]` pairs; scalars → `[kind payload]`. It needs no normalization. Equality is `=` on keys |
| `+norm-set` dedup | `lien` over the rest per element, O(n²) equality calls | a backward walk through a `(set *)` of keys, O(n log n). It still keeps the LAST of equal elements, in their original order |
| `+norm-set` / `+normalize` sorts | stdlib `+sort` with a `+vlth` gate: **48 ms for 100 integers** (about 70 µs per comparison through the gate) | `+vsort` / `+psort` / `+fsort`: hand-rolled STABLE merge sorts calling the comparator directly. Stable, like the stdlib quicksort's `skid` partition, so the order of ties is unchanged (asserted equal on the benchmark) |
| `+vlth` | every pair went through the fcn-like and kind-rank checks | an int/int and str/str fast path at the top, which is exactly what the arms below compute |
| `+key-set` | — | the `+silt` treap itself. A treap's shape is fixed by its elements (`+gor` keys and `+mor` priorities are both total), so equal sets give identical nouns with no sort |

`+equal-norm-ref` keeps the old pairwise relation as the SPECIFICATION
`+ekey` must match.

## Evidence

- **Differential test** (`tests/lib/value.hoon`
  `test-ekey-matches-reference`): 600 random values, nested to depth 3
  over every kind. Each is compared with itself, with a RE-REPRESENTED
  equal twin (reversed and duplicated elements, interval → set, tuple or
  record → function, reversed pairs), or with an independent value. The new
  `+equal` must agree with `+equal-norm-ref` over the normal forms in every
  case. **It bites:** with `key-set` not deduplicating, the arm FAILS.
- **Byte-identical behaviour:** 24 shards green after the final change
  (below), including perf (the tier-3 work profiles), mc, sim-diff,
  generate-diff, dfid, bags, core-eval, eval, stdops-diff, strorder,
  cfg-val, fuzz, job, app, blackbox and tier2.
- **Micro** (load average about 1):

  | measurement | before | after |
  |---|---|---|
  | `+equal`, two 100-sets | 151 ms | **0.49 ms** (×310) |
  | `+equal`, two 50-sets | 38 ms | 0.30 ms |
  | `state-fp`, state with a 100-set | 66 ms | **7.4 ms** (×9) |
  | `state-fp`, state with a 20-set | 3.3 ms | 1.36 ms |
  | `+norm-set`, 100 integers | 48 ms | 4.2 ms |

## Timed-out models (re-run through the runner, wall 900 s)

Through the runner at wall 300 s, load average about 1:

| model | before (R4.0e2, wall 900 s) | after R4.P4 (wall 300 s) | now bound by |
|---|---|---|---|
| GameOfLife | 7,424 distinct (about 8/s) | 21,760 (about 73/s, ×9) | time: 65,536 needed, about 15 min |
| ACP_SB_TLC | 20,770 (about 23/s) | 16,373 (about 55/s, ×2.4) | time: 54,944 needed, about 17 min |
| Paxos | 199 | 338 (×5 rate) | **H4**: `Message` re-built per state (R4.P3) |
| CoffeeCan100Beans | never left `%config` | `%config` 29 s, then the init registration | **H4**: `TypeInvariant == can \in Can` re-builds and normalizes `Can` (10,201 records) for each of 5,150 initial states (probe trace: `register` → `+norm-set`/`+vsort`) |
| EWD840_anim | stuck in `+norm-set` | **ends in 195 s**: `unsupported: ALIAS in simulation mode` | a correctness row (R4.2i) |

The `bottleneck` fields in `timed-out.json` are updated. **H4 (R4.P3) is
now the gate for both Paxos and CoffeeCan100Beans.** The list itself is
re-run and emptied at the R4.P close, per the tracker.
