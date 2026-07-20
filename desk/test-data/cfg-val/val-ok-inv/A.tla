---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x + 1
Inv == x >= 0
Op(a) == a + 1
Spec == Init /\ [][Next]_x
====
