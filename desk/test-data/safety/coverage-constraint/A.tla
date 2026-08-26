---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Inc == x < 5 /\ x' = x + 1
Dec == x > 0 /\ x' = x - 1
Next == Inc \/ Dec
Inv == x >= 0
ACons == x' # x
Cons == x < 3
====
