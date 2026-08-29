---- MODULE spec ----
EXTENDS Naturals, FiniteSets, Sequences, Randomization
VARIABLE x
Init == x = TestRandomSetOfSubsets(4, 2, 1..4)
Next == UNCHANGED x
Inv == Len(x) = 0
====
