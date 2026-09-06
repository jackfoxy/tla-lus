---- MODULE spec ----
EXTENDS Naturals, FiniteSets, Randomization
VARIABLES x, y
Init == x = RandomSubset(2, 1..9) /\ y = RandomSubset(2, 1..9)
Next == UNCHANGED <<x, y>>
Inv == x = y
====
