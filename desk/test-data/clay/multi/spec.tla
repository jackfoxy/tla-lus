---- MODULE spec ----
EXTENDS Naturals, helper
VARIABLE x
Init == x = 0
Next == x' = (x + 1) % 4
Inv == x < 4
====
