---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x \in {0, 3}
Next == x' = x
Spec == Init /\ [][Next]_x
ImpInit == x = 0
====
