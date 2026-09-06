---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 3 /\ x' = x + 1
Inv == x < 2
Alias == [ v |-> x, doubled |-> x * 2, moved |-> x' # x ]
====
