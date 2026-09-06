---- MODULE spec ----
EXTENDS Integers
VARIABLE x
Unused == 1.5
Init == x = 0
Next == x' = x + 1 /\ x < 3
====
