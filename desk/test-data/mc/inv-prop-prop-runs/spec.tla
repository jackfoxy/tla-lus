---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = (x + 1) % 4
Spec == Init /\ [][Next]_x
Inv == x < 9
Tight == x < 2
BoxSmall == [](x < 9)
BoxTight == [](x < 2)
Live == <>(x = 3)
====
