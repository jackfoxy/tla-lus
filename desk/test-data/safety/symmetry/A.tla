---- MODULE A ----
EXTENDS Naturals, TLC
CONSTANT P
VARIABLE x
Init == x \in P
Next == \E p \in P : x' = p
Perms == Permutations(P)
Inv == TRUE
====
