---- MODULE spec ----
EXTENDS Naturals, FiniteSets, Randomization
VARIABLES x, y
Init == x = {} /\ y = {}
Next == /\ \/ x = {}
           \/ x # y
        /\ x' = RandomSubset(1, 1..3)
        /\ y' = RandomSubset(1, 1..3)
Inv == Cardinality(x) <= 1
====
