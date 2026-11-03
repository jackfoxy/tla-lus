---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == /\ x < 2
        /\ x' = x + 1
        /\ \E q \in {1, 2, 3} : q > 0
====
