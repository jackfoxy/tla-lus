---- MODULE spec ----
EXTENDS Naturals, TLC
VARIABLE x
Init == x = 0 /\ TLCSet(0, 7)
Next == /\ x < 2
        /\ TLCSet(0, 42)
        /\ x' = TLCGet(0)
Inv == x >= 0
====
