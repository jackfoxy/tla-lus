---- MODULE A ----
EXTENDS Naturals
VARIABLE x
ASSUME 1 + 1 = 2
Init == x = 0
Next == x' = (x + 1) % 3
Inv == x < 3
====
