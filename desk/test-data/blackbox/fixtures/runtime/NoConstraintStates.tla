---------------------------- MODULE NoConstraintStates ----------------------------
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x
Spec == Init /\ [][Next]_x
Constraint == x > 5
=============================================================================
