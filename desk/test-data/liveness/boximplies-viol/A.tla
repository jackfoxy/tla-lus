---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Step == x < 3 /\ x' = x + 1
Spec == Init /\ [][Step]_x
Live == [](x = 1 => [](x # 3))
====
