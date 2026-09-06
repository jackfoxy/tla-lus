---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Inc == x < 3 /\ x' = x + 1
Dec == x > 0 /\ x' = x - 1
Next == Inc \/ Dec
Inv == TRUE
====
