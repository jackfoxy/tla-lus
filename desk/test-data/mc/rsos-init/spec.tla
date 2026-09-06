---- MODULE spec ----
EXTENDS Naturals, FiniteSets, Randomization
VARIABLE x
Init == x = RandomSetOfSubsets(4, 2, 1..4)
Next == UNCHANGED x
Inv == Cardinality(x) < 4
====
