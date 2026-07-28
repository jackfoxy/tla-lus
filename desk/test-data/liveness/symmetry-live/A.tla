---- MODULE A ----
EXTENDS TLC
VARIABLE x
CONSTANT S
Init == x \in S
Next == \E s \in S : x' = s
Perms == Permutations(S)
Spec == Init /\ [][Next]_x /\ WF_x(Next)
Live == []<>(\E s \in S : x = s)
====
