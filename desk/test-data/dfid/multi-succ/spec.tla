---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' \in {1, 2, 3}
Inv == x /= 2
====
