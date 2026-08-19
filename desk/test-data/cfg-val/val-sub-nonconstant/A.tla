---- MODULE A ----
EXTENDS Naturals
CONSTANT C
VARIABLE x
V == x + 1
Init == x = C
Next == x' = x + 1
====
