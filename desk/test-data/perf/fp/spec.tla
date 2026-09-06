---- MODULE A ----
\* Hot path: FINGERPRINTING. Every state carries a record and a sequence, so
\* each dedup pays a full structural +fp-enc rather than an integer one.
EXTENDS Integers, Sequences
VARIABLE r
Init == r = [a |-> 0, b |-> <<0, 0, 0>>, c |-> "z"]
Next == /\ r.a < 60
        /\ r' = [a |-> r.a + 1,
                 b |-> <<r.a, r.a + 1, r.a + 2>>,
                 c |-> r.c]
Inv  == r.a >= 0
====
