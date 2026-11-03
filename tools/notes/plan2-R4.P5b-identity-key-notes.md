# R4.P5b: identity key, measured; the decision is the user's (2026-10-12)

**Status: MEASURED.** Per r13, the user decides at the R4.P close.

## The cost

One state of three variables (a 100- or 400-element set, a sequence of the
same length, a two-field record), N repetitions in one build (scratch
profiler), at a load average of about 1:

| | 100 elements, 50 states | 400 elements, 20 states |
|---|---|---|
| FP64 `+state-fp` (normalize + FP64), after R4.P5 | 456–487 ms | 784 ms |
| `+normalize` alone | 49–52 ms | 87 ms |
| **identity key**: `(sham (jam normalized-values))` | **51–56 ms** | **86 ms** |

The key costs what normalization costs: `+jam` and `+sham` (SHA-256) are
jetted and nearly free. FP64 is about **9× the key**, because 64-bit atoms
are indirect and FP64 is folded byte by byte in Hoon (R4.P5 notes).

## Where FP64 is observable (read from the code)

| place | observable? | consequence for a swap |
|---|---|---|
| safety BFS: queue, `seen`, traces, counts | **no**: FIFO and discovery order only; `seen` is only looked up | key freely |
| `-continue` violations | no: discovery order | key freely |
| RNG reseed per expanded state, `fp ^ seed` (R2.7.4.4) | **yes**, and only when the spec draws (`RandomElement`, `RandomSubset`, …, statically detectable) | compute FP64 for expanded states of such specs only |
| liveness: product vertices via `~(tap by nodes)` over `[fp tidx]`, the no-tableau product via `~(tap by states)` | **yes**: map order follows the key's hash, and Tarjan's root order decides WHICH lasso is reported | keep FP64 keys for every run that builds the temporal graph |
| tlc2's end-of-run "fingerprint collision probability" line (reads actual fingerprint distances) | not printed by the port | none |
| simulation / DFID | DFID keys its visited set the same way as BFS; simulation reseeds per state like BFS | same rules as BFS |

## Collisions

tlc2 merges two states whose FP64 values collide. A 256-bit key merges
none in practice. A spec whose FP64 collides would then report MORE
distinct states than tlc2: not byte-identical in principle, with negligible
probability (tlc2 itself prints the estimate as a warning). That is an
approved-difference row if the swap is taken.

## The proposal (for the user's decision)

1. Safety BFS and DFID: identity = `sham` of the jammed normalized state
   (with the orbit representative / VIEW value as today). FP64 is computed
   only for an expanded state of a spec that draws random values (the
   reseed).
2. Every run that builds a temporal graph keeps FP64 as the key, so lasso
   selection is unchanged.
3. A new approved-difference row for the collision semantics.

Expected effect: identity cost per state about 9 ms → about 1 ms on
set-heavy states. The throughput gain is bounded by identity's share of a
step, which varies by model and is not yet measured per model.

Alternative: keep FP64 everywhere. It costs nothing in fidelity and
nothing in work, and keeps the ~5 µs-per-byte floor.
