---- MODULE spec ----
EXTENDS Naturals
VARIABLE x, y
Init == x = 0 /\ y = 0
Next == /\ x' = (x + 1) % 3
        /\ y' = (y + 1) % 2
Inv == x < 3
Vw == x
====
