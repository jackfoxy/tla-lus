---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x \in {0, 1, 2}
Next == x' = (x + 1) % 3
====
