---- MODULE A ----
EXTENDS Naturals
VARIABLES a, b
Init == a = 0 /\ b = 0
Next == \/ /\ a = 0 /\ a' = 1 /\ b' = b
        \/ /\ b = 0 /\ b' = 1 /\ a' = a
Inv == ~(a = 1 /\ b = 1)
====
