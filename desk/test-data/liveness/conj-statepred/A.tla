---- MODULE A ----
EXTENDS Naturals
VARIABLE x, y
Init == x = 0 /\ y = 0
Next == x' = 1 - x /\ y' = y
Live == <>(x = 1 /\ y = 0)
====
