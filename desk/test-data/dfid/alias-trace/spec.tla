---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x + 1
Inv == x < 3
Alias == [ v |-> x, doubled |-> x * 2 ]
====
