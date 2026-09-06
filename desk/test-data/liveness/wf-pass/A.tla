---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Inc == x < 3 /\ x' = x + 1
Next == Inc \/ (x = 3 /\ x' = 3)
Spec == Init /\ [][Next]_x /\ WF_x(Inc)
Live == <>(x = 3)
====
