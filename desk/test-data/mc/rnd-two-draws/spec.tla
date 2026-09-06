---- MODULE spec ----
EXTENDS Naturals, TLC
VARIABLES x, y
Init == x = 0 /\ y = 0
Next == /\ x < 3
        /\ x' = RandomElement(0..2)
        /\ y' = RandomElement(0..2)
Inv == x <= 2
====
