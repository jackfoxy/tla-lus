---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Step == x < 3 /\ x' = x + 1
Spec == Init /\ [][Step]_x
NeverThree == [](x = 1 => [](x # 3))
Tautology == (x = x) ~> (x = x)
====
