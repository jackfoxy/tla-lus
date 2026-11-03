# R4.P5: the fingerprint path (H6) (2026-10-11)

**Status: the mechanical half is DONE. The identity-key half is a decision
for the check-in after R4.P6.**

## What was measured

A scratch profiler (ship-only) times one state of three variables: a set of
100 integers, a sequence of the same 100, and a two-field record. It takes
50 repetitions, at a load average of about 1.5. Both paths are in the same
build, so this is a true A/B, and the A and B fingerprints are asserted
equal on every run.

| 50 states | before | after |
|---|---|---|
| `+state-fp` (normalize + encode + FP64) | 663–701 ms (13.3 ms/state) | 451–466 ms (9.2 ms/state) |
| `+normalize` of the three values alone | 205–208 ms | 49–66 ms |
| FP64 over the normalized 100-set alone | 152–166 ms | 127–149 ms |

End to end, GameOfLife through the runner at `--wall 300`: **21,760
distinct (R4.P4) → 29,952**, 73 → 97 states/s.

## Changes (byte-identical fingerprints)

- `lib/fingerprint` `+fp-walk`: FP64 is folded over a normalized value as
  its bytes are produced. There is no byte list and no nested `+weld`.
  `+state-fp` and `+fp-value` use it. `+fp-bytes`/`+fp-input` stay for the
  tests and the WU6.8 byte goldens.
- ByteModTable_7 is one 2 KiB atom read with `+cut` (it was a map lookup per
  byte). `+fp-word` feeds a word's low bytes in one loop (integers, string
  and model-value characters).
- `lib/value` `+i32`: a Java int's low 32 bits by bit arithmetic on the
  `@sd` encoding. It was `+old:si` and `+bex` per integer. `+int32-le` uses
  it.
- `lib/value` `+norm-set` fast path `+sorted-scalars`: a list of integers
  only, or strings only, that is already strictly increasing in storage
  order is distinct and in place, so it is returned as is. Every
  fingerprint re-normalizes each value, so this is the common case. It is
  restricted to integers and strings because there "distinct in `+vlth`"
  implies "unequal". For composites, equal values in different
  representations would break that.

## Tests

- `tests/lib/value` `test-fp-walk-matches-bytes`: 400 random values, plus a
  model value, a negative integer and a string. `+fp-walk` must equal FP64
  over the `+fp-enc` byte list.
- `tests/lib/value` `test-i32-matches-reference`: `+i32` against the
  `+old:si` formula, across the sign, the 32-bit boundary and wrap-around.
- `tests/lib/fp` (the pin's FP64 vectors) green; the full suite re-run on
  this code (see the tracker).

## Why it is not faster: FP64 in Hoon

Folding whole words gained nothing over a gate call per byte. The cost is
in the arithmetic. An FP64 value is 64 bits, and a Nock atom over 31 bits
is indirect, so each byte step's `mix`/`rsh`/`cut` allocates. That is about
5 µs per byte, and a state of 200 integers is about 1,000 bytes.

## The decision owed (the plan's "collision argument")

The way past this is to key the visited set on a **jetted identity key**,
such as `+mug` or `+shax` of the jammed normalized value. FP64 would then be
computed only where it is observable. That is not a refactor, and these
must be measured first:

1. **Where FP64 is observable:** the `fp ^ seed` RNG reseed per expanded
   state (R2.7.4.4, only when the spec draws); liveness and graph exports
   that print or order by fingerprint; trace reconstruction (R4.P6).
2. **Iteration order:** any walk over a map keyed by fingerprint (the
   liveness graph, `+states-of`) changes order with the key, and an order
   can leak into output.
3. **Collisions:** tlc2's behaviour under an FP64 collision is to treat two
   states as one. A different 64-bit (or 256-bit) key changes which pairs
   collide. The probability is negligible, but the behaviour is not
   byte-identical in principle, so it is an approved-difference question.
