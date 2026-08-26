---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x \in 0..3 /\ x > 1
Next == x' = x
Inv == x >= 0
====
