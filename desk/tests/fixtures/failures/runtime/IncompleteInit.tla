---------------------------- MODULE IncompleteInit ----------------------------
EXTENDS Naturals
VARIABLES x, y
Init == x = 0
Next == /\ x' = x
        /\ y' = y
Spec == Init /\ [][Next]_<<x, y>>
=============================================================================
