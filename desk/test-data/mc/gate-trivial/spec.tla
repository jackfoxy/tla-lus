---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x
Falsy == FALSE
Spec == Falsy /\ Init /\ [][Next]_x
====
