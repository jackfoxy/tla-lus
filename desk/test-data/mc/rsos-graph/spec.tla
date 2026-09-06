---- MODULE spec ----
EXTENDS Naturals, FiniteSets, Randomization
VARIABLE x
Init == x = {{1, 2, 3}}
Next == /\ {} \notin x
        /\ x' = RandomSetOfSubsets(3, 1, 1..3)
Inv == Cardinality(x) <= 3
====
