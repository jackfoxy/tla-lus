---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Step == \/ x = 0 /\ x' = 1
        \/ x = 0 /\ x' = 5
        \/ x = 1 /\ x' = 2
        \/ x = 2 /\ x' = 3
Spec == Init /\ [][Step]_x
NoTwo == [](x = 1 => [](x # 2))
====
