---- MODULE spec ----
EXTENDS Naturals, TLC
VARIABLE x
Init == x = 0
Next == /\ x < 3
        /\ \E i \in 1..2 : x' = RandomElement(0..2)
Inv == x <= 2
====
