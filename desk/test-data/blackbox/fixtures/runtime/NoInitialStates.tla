---------------------------- MODULE NoInitialStates ----------------------------
EXTENDS Naturals
VARIABLE x
Init == /\ x = 0
        /\ x = 1
Next == x' = x
Spec == Init /\ [][Next]_x
=============================================================================
