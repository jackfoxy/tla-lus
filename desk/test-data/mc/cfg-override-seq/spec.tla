---- MODULE spec ----
\* R4.2m: `Seq <- LimitedSeq` (LoopInvariance's MCQuicksort/MCBinarySearch):
\* the overridden `Seq(S)` is the finite definition, so it enumerates.
EXTENDS Naturals, Sequences
VARIABLE s
LimitedSeq(S) == UNION {[1 .. n -> S] : n \in 1 .. 2}
Init == s \in Seq({0, 1})
Next == UNCHANGED s
====
