---- MODULE spec ----
EXTENDS Naturals, TLC
VARIABLE x
Init == x = 0 /\ TLCSet(0, 100)
Next == /\ x < 4
        /\ TLCSet(0, TLCGet(0) + 1)
        /\ x' = TLCGet(0) - 100
Inv == x < 10
====
