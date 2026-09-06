---- MODULE spec ----
EXTENDS Naturals
VARIABLES x, y
Init == x = 0 /\ y = 0
A == x' \in {1, 2} /\ y' = y
B == y' = 1 /\ x' = x
Next == B \/ A
Inv == y = 0
====
