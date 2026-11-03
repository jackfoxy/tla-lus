---- MODULE spec ----
EXTENDS Naturals, TLC
CONSTANT K0
VARIABLE x
Init == x = 0
Next == x < 10 /\ x' = x + 1
Lvl == TLCGet("level") < K0
====
