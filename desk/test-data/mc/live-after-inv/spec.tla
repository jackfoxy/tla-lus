---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Step == x < 5 /\ x' = x + 1
Spec == Init /\ [][Step]_x
Inv == x < 3
P2 == [](x = 0 => [](x # 2))
====
