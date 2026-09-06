---- MODULE spec ----
EXTENDS Naturals
VARIABLES x, y
Init == x = 0 /\ y = 0
Next == x' = (x + 1) % 3 /\ y' = y
Spec == Init /\ [][Next]_x
Inv == x < 9
====
