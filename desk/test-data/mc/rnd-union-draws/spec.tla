---- MODULE spec ----
EXTENDS Integers, FiniteSets, TLC
Nodes == 1..4
Edges == UNION { {{n, m} : m \in RandomElement(SUBSET (Nodes\{n}))} : n \in Nodes }
VARIABLE x
Init == x = Edges
Next == UNCHANGED x
Inv == x = {}
====
