---- MODULE A ----
EXTENDS Naturals
CONSTANT C
VARIABLE x
Init == x = C
Next == x' = x + 1
Inv == x >= 0
Op(a) == a + 1
Spec == Init /\ [][Next]_x
====
