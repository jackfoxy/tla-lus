---------------------------- MODULE IncompleteNext ----------------------------
EXTENDS Naturals
VARIABLES x, y
Init == /\ x = 0
        /\ y = 0
Next == x' = x + 1
Spec == Init /\ [][Next]_<<x, y>>
=============================================================================
