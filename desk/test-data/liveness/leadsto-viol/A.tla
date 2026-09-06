---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == \/ x' = x
        \/ (x = 0 /\ x' = 1)
Live == (x = 0) ~> (x = 1)
====
