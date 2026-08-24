---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = (x + 1) % 3
MyInit(i) == i
Spec == MyInit(Init) /\ [][Next]_x
Inv == x < 9
====
