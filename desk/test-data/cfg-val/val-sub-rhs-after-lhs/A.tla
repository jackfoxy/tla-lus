---- MODULE A ----
EXTENDS Naturals
CONSTANT C
VARIABLE x
Foo == 1
Bar == 2
Init == x = C
Next == x' = x + 1
====
