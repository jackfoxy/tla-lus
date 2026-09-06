---- MODULE A ----
EXTENDS Naturals
CONSTANT C
VARIABLE x
Init == x = C
Next == x' = x + 1
====
