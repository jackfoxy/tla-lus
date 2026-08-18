---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = (x + 1) % 4
Spec == Init /\ [][Next]_x
ImpAct == [][x' # x]_x
====
