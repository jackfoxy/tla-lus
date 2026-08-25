---- MODULE spec ----
EXTENDS Naturals
VARIABLES x, y
Init == x = 0 /\ y = 0
Next == (x' = x + 1 /\ y' = y) \/ (y' = y + 1 /\ x' = x)
Inv == x + y < 3
====
