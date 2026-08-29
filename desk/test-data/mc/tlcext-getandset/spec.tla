---- MODULE spec ----
EXTENDS Naturals, TLC, TLCExt
VARIABLE x
Add(a, b) == a + b
Init == x = 0
Next == /\ x < 3
        /\ x' = TLCGetAndSet(1, Add, 10, 0) + 1
Inv == x >= 0
====
