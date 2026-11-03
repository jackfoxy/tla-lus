---- MODULE spec ----
EXTENDS Naturals
---- MODULE Inner ----
EXTENDS Naturals
CONSTANT Constraint(_, _)
VARIABLE x
Init == x = 0
Next == x < 3 /\ Constraint(x, 1) /\ x' = x + 1
====
VARIABLE x
M == INSTANCE Inner WITH Constraint <- LAMBDA s, l : s < 2
Init == M!Init
Next == M!Next
====
