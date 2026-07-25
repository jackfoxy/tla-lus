---- MODULE A ----
EXTENDS Naturals
VARIABLE x
ASSUME 1 + 1
Init == x = 0
Next == x' = x
Inv == TRUE
====
