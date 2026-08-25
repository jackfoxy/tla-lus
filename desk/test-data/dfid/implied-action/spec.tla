---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x + 1
NoJump == [][x' =< 2]_x
====
