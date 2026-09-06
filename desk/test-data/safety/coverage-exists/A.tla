---- MODULE A ----
EXTENDS Naturals
VARIABLES x, y
Init == x = 0 /\ y = 0
Bump(i) == /\ x' = (x + i) % 3
           /\ y' = y
Yup == /\ y' = (y + 1) % 2
       /\ x' = x
Next == (\E i \in 1..2 : Bump(i)) \/ Yup
Inv == x < 3
====
