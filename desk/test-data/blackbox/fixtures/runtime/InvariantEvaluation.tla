---------------------------- MODULE InvariantEvaluation ----------------------------
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x + 1
Spec == Init /\ [][Next]_x
Inv  == (1 \div x) >= 0
=============================================================================
