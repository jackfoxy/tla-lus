# R4.Q2 + R4.Q3 notes (2026-10-24)

## Q2 — draw/print flags (H13): measured, no change

`+sem-draws` stubbed to `|` on a ship-only build, A/B on the Q0 probes
(second runs, alternating builds): p08 `\E j \in {k} : TRUE` 5.45 → 5.3 s
per 20,000 elements (≈5 µs per binder evaluation), p14 unchanged. The
`~+` memo on `+reach-names` already makes the test cheap. No code change.

## Q3 — normalization and equality keys (H14)

Probes `%tla-ex zprobe/q3/` (`ASSUME \A k \in 1..20 : <expr>`, one
256-element set per step; times are the %config slice minus `b0`, per set):

| probe | expr | before | after |
|---|---|---|---|
| b1 | `Cardinality({f : f \in [1..4 -> S]})` | 227 ms | ≈95 ms (×2.4) |
| b2 | `Cardinality({<<a, b>> : a, b \in 16})` | 122 ms | 40 ms (×3.0) |
| b5 | `Cardinality({[a |-> i, b |-> j] : ...})` | 131 ms | 46 ms (×2.8) |
| c2 | `Cardinality([1..4 -> S])` | 97 ms | 37 ms (×2.6) |
| b6 | `Cardinality(SUBSET S)`, 8 elements | 54 ms | 38 ms |
| b3 | `Cardinality({a * 100 + b : ...})` | 63 ms | 53 ms (arithmetic-bound) |

Run-to-run noise is ≈10–15% (b0 0.8–1.1 s).

Findings:

1. `+force` normalized the elements a second time (a set-map image is
   normalized by `+map-over`, then `Cardinality`'s `+force` does it again),
   and its accumulator is REVERSED, so R4.P5's `+sorted-scalars` shortcut
   never fired on a forced set.
2. `+vlth` on composites called `+equal-norm`, i.e. two `+ekey`s per
   element compared (a 2-tuple's key ≈28 µs).

Changes (`lib/value.hoon`):

- `+equal`: identical nouns, scalars, intervals, and position-by-position
  equal seq/set/fcn/rec lists answer before any key is built. Each is exact.
- `+norm-set`: `+rising` (strictly increasing, or reversed) returns the
  list as it is; all-scalar lists dedup by sort (`+drop-twins`).
- `+normalize` returns a `+normal` set unchanged.
- `+rising` refuses any value containing an interval: `+vlth` ranks an
  interval by kind and `lo`, so `<<1..2>> < <<5>> < <<{1, 2}>>` rises while
  its ends are equal. Arm `test-q3-rising-skips-intervals` (bites: 3
  without the guard); `test-q3-equal-across-forms`.

Not done: caching `+ekey` (`+equal` now reaches it only when the fast paths
do not decide); building lazy sets pre-sorted (the generic `+rising` check
covers the odometer's output, which is already in storage order).

Regression 65/65 (`logs/q3-regress1.txt`); validate, scaffold-gate,
test-examples PASS.

## Targeted census (`logs/census-q3.txt`, census-q1's 14 rows)

Every count unchanged (generated/distinct/depth equal on all 14).

| model | census-q1 | census-q3 |
|---|---|---|
| SpanTreeTest4Nodes | 584 s | 336 s |
| AsyncTerminationDetection | 321 s | 176 s |
| TestGraphs | 336 s | 262 s |
| ACP_NB_TLC | 503 s (277 after Q8) | 301 s |
| SimpleAllocator | 348 s (179 after Q8) | 179 s |
| MCEWD687a (1,000 states) | 409 s | 346 s |
| MCReachable | 162 s | 138 s |
| Chameneos | 335 s | 378 s |
| VoucherIssue | 371 s | 414 s |
| LockHS | 15 s | 26 s (startup-sized; not re-measured) |
| EWD998ChanID, TLCSailfish2, EWD998Chan, MCNanoLarge | | within ±4 s |

Chameneos and VoucherIssue looked slower, so a same-day A/B
(`q3-ab.sh`, `logs/census-q3ab-*.txt`), after trimming the failure-path
overhead (`+falling` instead of reversing; `+vlth` before the interval
scan; the `+normal` precheck on sets only):

| model | HEAD | Q3 | Q3 again |
|---|---|---|---|
| Chameneos | 421 s | 366 s | 398 s |
| VoucherIssue | 446 s | 400 s | 399 s |

HEAD itself ran 20% slower than in census-q1: the box drifts between days,
so only same-session A/B comparisons are meaningful.

After the trim: regression 65/65 again (`logs/q3-regress2.txt`).
