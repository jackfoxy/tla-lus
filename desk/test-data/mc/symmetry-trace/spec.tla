---- MODULE spec ----
EXTENDS Naturals, TLC
CONSTANT P, a, b
VARIABLE n, x
Init == x = a /\ n = 0
Next == n < 2 /\ n' = n + 1 /\ x' = IF x = a THEN b ELSE a
Perms == Permutations(P)
Inv == n < 2
====
