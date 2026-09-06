---- MODULE A ----
EXTENDS Naturals
CONSTANT C
VARIABLE x
Bar(a) == a + 1
Init == x = C
Next == x' = x + 1
====
