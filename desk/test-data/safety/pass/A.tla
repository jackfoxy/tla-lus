---- MODULE A ----
EXTENDS Naturals
VARIABLES x, y
Init == x = 0 /\ y = 0
Next == \/ /\ x' = (x + 1) % 2
           /\ y' = y
        \/ /\ y' = (y + 1) % 2
           /\ x' = x
Inv == x < 2 /\ y < 2
====
