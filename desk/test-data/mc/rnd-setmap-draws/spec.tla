---- MODULE spec ----
EXTENDS Naturals, TLC
VARIABLE x
Init == x = << {RandomElement(SUBSET ({1, 2, 3} \ {n})) : n \in {1, 2}},
               [n \in {1, 2, 3} |-> RandomElement(1..9)] >>
Next == UNCHANGED x
Inv == x[1] = {}
====
