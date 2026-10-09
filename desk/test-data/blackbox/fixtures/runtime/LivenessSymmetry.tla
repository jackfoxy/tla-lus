---------------------------- MODULE LivenessSymmetry ----------------------------
EXTENDS Naturals, TLC
CONSTANT S
VARIABLE x
Init == x \in S
Next == x' = x
Spec == Init /\ [][Next]_x /\ WF_x(Next)
Sym  == Permutations(S)
Live == <>(x = x)
=============================================================================
