---- MODULE spec ----
EXTENDS Naturals, FiniteSets, Randomization
VARIABLE x
Init == x = {}
Next == /\ 1 \notin x
        /\ x' = RandomSubset(2, 1..5)
Inv == Cardinality(x) <= 2
====
