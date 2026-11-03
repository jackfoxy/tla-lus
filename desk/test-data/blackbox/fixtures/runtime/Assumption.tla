---------------------------- MODULE Assumption ----------------------------
EXTENDS Naturals
ASSUME 1 = 2
VARIABLE x
Init == x = 0
Next == x' = x
Spec == Init /\ [][Next]_x
=============================================================================
