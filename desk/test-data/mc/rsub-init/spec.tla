---- MODULE spec ----
EXTENDS Naturals, FiniteSets, Randomization
VARIABLE x
Init == x = RandomSubset(3, 1..10)
Next == UNCHANGED x
Inv == Cardinality(x) < 3
====
