---- MODULE spec ----
EXTENDS Naturals, TLC, TLCExt
VARIABLE x
Init == x = TLCGetOrDefault(5, 0)
Next == /\ x < 3
        /\ TLCSet(5, 1)
        /\ x' = x + TLCGetOrDefault(5, 99)
Inv == x >= 0
====
