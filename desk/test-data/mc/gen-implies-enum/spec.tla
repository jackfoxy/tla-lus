---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 2 /\ (TRUE => \E a \in {1, 2} : a > 0) /\ x' = x + 1
====
