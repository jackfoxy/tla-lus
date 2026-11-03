# R4.Q4 notes — the startup class (2026-10-24)

Q0 found 8 models that sat in one `%config` slice past its 300 s wall.
Each was probed at a reduced size (mount-only `zq4*` configs in the `%tla-ex`
spec directories, modules in `zprobe/q4`), then at full size through
`probe2.py` (agent path, watchdog). They are not one class.

| model | finding | full size |
|---|---|---|
| MC_sums_even | `ASSUME \A x \in 0..1000000 : Even(x+x)`, ≈270 µs/element | **success 264 s** |
| MCReachabilityTestAllGraphs | ASSUMEs over `[Nodes -> SUBSET Nodes]` | **success 389 s** |
| TransitiveClosure | REFUSED `CR[n \in Nat, v \in S]` (fixed, below); then evaluator-bound: ASSUME 1 ≈2.5 s per 4-pair relation (TC1 tries up to 9 × 121 bounded sequences), ASSUME 2 > 4 s | limited time (one ≈1,020 s slice); tlc2 5 s |
| CarTalkPuzzle Model_1 | `ExpandSolutions` enumerates 40^4 = 2.56M functions at startup — tlc2 too (10 s before its first print) | out of reach |
| CarTalkPuzzle Model_2 | the same over 15^4 = 50,625: `Sum` ≈2.8 ms, sortedness ≈3 ms per function | limited time (≈1,020 s slice) |
| CarTalkPuzzle Model_3 | 121^5 functions | out of reach (no manifest runtime) |
| MCBakery | 655,200 distinct; per-state throughput | out of reach at ≈100 distinct/s |
| MCBinarySearch | 27,953 distinct; ≈17 distinct/s at MaxSeqLen 5 | throughput-bound |
| YoYoAllGraphs | 26,731 distinct; ≈6 distinct/s at N = 4 | throughput-bound |

So two complete as they stand (they were only cut by the 300 s wall), and
the rest are the general per-node evaluator cost (≈100–1,000× tlc2), not a
startup phase.

Pitfall: a dojo path literal with `_` (`/specifications/sums_even`) hangs
`zstep` before its first step; the agent path is unaffected.

## Fix: recursive functions over several binders (TransitiveClosure)

`LET CR[n \in Nat, v \in S] == ... IN CR[Cardinality(S)-1, t]` was refused
("function constructor over multiple binders is unsupported"). tlc2 keeps a
lazy FcnLambdaValue. `+recfcn-infinite` / `+apply-recfcn` (lazy, Nat/Int
domains) and `+eval-recfcn` (finite) now take several binders: points are
tuples (`f[a, b]` is `f[<<a, b>>]`), an infinite dimension sweeps 0 to the
argument's component, a finite one every element (`+recfcn-dim`,
`+recfcn-product`, `+bind-point`). The reduced TransitiveClosure (N ≤ 2)
now succeeds, as tlc2 does. Arms `test-q4-recfcn-two-binders-nat`,
`-cross`, `-finite` (each was refused before).

## H22: LET definitions re-evaluated per reference

A LET's arity-0 definition has no origin, and the R4.P11/R4.3 memo
skipped origin `''`, so every reference re-evaluated the body; tlc2 binds a
LazyValue evaluated once. Now memoized like module definitions when heavy
(the key is exact). Probes (per element):
`LET B == [i \in 1..4 |-> k] IN \A i \in 1..4 : \A j \in (i+1)..4 : B[i] =< B[j]`
6.5 → 3.1 ms; CarTalk's `Sum` over 4 elements 3.4 → 2.8 ms.

## Gates and census

Regression 65/65 (`logs/q4-regress1.txt`); validate, scaffold-gate,
test-examples PASS. Targeted census `logs/census-q4.txt` (census-q3's 14
rows + the two startup-class rows), same session as census-q3's A/B:

| model | census-q3 | census-q4 |
|---|---|---|
| TestGraphs | 262 s | 223 s |
| Chameneos | 378 s | 323 s |
| ACP_NB_TLC | 301 s | 262 s |
| SpanTreeTest4Nodes | 336 s | 297 s |
| VoucherIssue | 414 s | 330 s |
| AsyncTerminationDetection | 176 s | 154 s |
| SimpleAllocator | 179 s | 159 s |
| MCEWD687a (1,000 states) | 346 s | 267 s |
| TLCSailfish2 (1,000 states) | 214 s | 166 s |
| **MC_sums_even** | — | **success 255 s** |
| **MCReachabilityTestAllGraphs** | — | **success 347 s** |
| the other 5 | | 5–20% faster |

Every count unchanged.
