---- MODULE spec ----
EXTENDS Naturals, FiniteSets
VARIABLE U
DPs(n) == {D \in SUBSET SUBSET (1..n) :
             /\ (UNION D) = 1..n
             /\ \A I, J \in D : (I # J) => (I \cap J = {}) }
Init == U = {{1, 2}, {3}, {4}}
Next == U' \in {{{1, 2, 3, 4}}, {{1}, {2, 3, 4}}, {{1, 2}, {2, 3, 4}}}
Inv == U \in DPs(4)
====
