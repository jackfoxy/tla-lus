# R4.2ag: MCQuicksort (2026-10-13)

**Status: the wrong error is gone; the model is slow (R4.3).**

The census error `Attempted to apply function <<2>> to argument 2` no longer
reproduces: a reduced `PermsOf`/`**` probe agrees with the pin, and the model
now explores (it was fixed in passing by the R4.2 evaluator-scope work).

What it then showed was speed. One job slice ran for 25+ minutes at flat
memory: `Inv`'s `UV \in DomainPartitions` filters `SUBSET SUBSET
(1..Len(seq0))`, and `+memb-node` had no set-filter case, so every state
materialized all 65,536 subsets and evaluated the filter on each. (Stopping
that slice crashed the ship -- see the tracker's unplanned line.)

## Fixes (`+memb-node`)

- `x \in {y \in S : P}` is `x \in S /\ P[y := x]`, decided lazily, as
  tlc2's `SetPredValue.member`.
- An APPLICATION of a user operator (`U \in DPs(4)`) is expanded like a
  zero-arity definition: arguments bound in the caller's env
  (`+bind-params`), membership decided on the body.

mc `memb-filter-lazy` (pin golden): 3 s on the console path; it ran past
10 minutes before.

## Still open

- MCQuicksort: 779 distinct at the 720 s wall (pin: 4,548 in seconds) --
  about 1 s per state, cause not profiled. R4.3.
- A CONSTANT definition whose body is a large set filter is precomputed by
  `+with-cdefs` (tlc2 keeps a `SetPredValue` lazy): `DP == {D \in SUBSET
  SUBSET (1..4) : ...}` costs about 5 minutes once at startup. Not seen in
  the corpus yet.
