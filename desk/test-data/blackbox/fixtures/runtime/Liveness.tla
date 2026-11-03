---------------------------- MODULE Liveness ----------------------------
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x
Spec == Init /\ [][Next]_x /\ WF_x(Next)
Live == <>(x = 1)
=============================================================================
