---- MODULE spec ----
EXTENDS Naturals, TLC
VARIABLE x
Init == x = 0
Next == x < 4 /\ x' = x + 1
Inv == TLCGet("distinct") < 3 /\ TLCGet("generated") < 4 /\ TLCGet("queue") < 2 /\ TLCGet("diameter") < 4
====
