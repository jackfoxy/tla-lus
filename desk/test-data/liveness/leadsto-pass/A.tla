---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Go == x = 0 /\ x' = 1
Next == Go \/ (x = 1 /\ x' = 1)
Spec == Init /\ [][Next]_x /\ WF_x(Go)
Live == (x = 0) ~> (x = 1)
====
