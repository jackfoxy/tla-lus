---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x = 5
Next == x' = x
Inv == x < 3
====
