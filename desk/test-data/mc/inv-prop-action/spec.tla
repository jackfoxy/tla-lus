---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = (x + 1) % 4
Spec == Init /\ [][Next]_x
Zero == x < 1
NoStep == [][x' = x]_x
====
