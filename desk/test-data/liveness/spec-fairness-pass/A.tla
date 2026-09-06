---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Inc == x < 2 /\ x' = x + 1
Next == Inc \/ (x = 2 /\ x' = 2)
Fairness == WF_x(Inc)
Spec == Init /\ [][Next]_x /\ Fairness
Live == <>(x = 2)
====
