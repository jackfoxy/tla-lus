---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = 1 \/ x' = 0
Spec == Init /\ [][Next]_x
Live == []<>(x = 1)
====
