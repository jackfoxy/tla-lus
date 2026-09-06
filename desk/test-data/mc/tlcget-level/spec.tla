---- MODULE spec ----
EXTENDS Naturals, TLC
VARIABLE x
Init == x = 0
Next == x < 6 /\ x' = x + TLCGet("level")
Inv == x < 5
====
