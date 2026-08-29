---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Step == \/ x = 0 /\ x' = 1
        \/ x = 1 /\ x' = 2
Spec == Init /\ [][Step]_x
Live == <>(x = 9)
====
