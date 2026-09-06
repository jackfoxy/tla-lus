---- MODULE spec ----
EXTENDS Naturals
VARIABLES x, y
Init == x = 0 /\ y = 0
Next == (x < 2 /\ x' = x + 1 /\ y' = y) \/ (y < 2 /\ y' = y + 1 /\ x' = x)
====
