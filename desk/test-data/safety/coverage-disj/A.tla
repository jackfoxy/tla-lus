---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Next == (x = 0 /\ x' = 1) \/ (x = 1 /\ x' = 0)
Init == x = 0
Inv == x < 2
====
