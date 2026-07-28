---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
A == x = 0 /\ x' = 1
B == x = 1 /\ x' = 0
Next == A \/ B
Spec == Init /\ [][Next]_x /\ WF_x(A)
Live == <>[](x = 1)
====
