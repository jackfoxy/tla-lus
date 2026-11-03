---------------------------- MODULE ActionProperty ----------------------------
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x + 1
Spec == Init /\ [][Next]_x
Increases == [][x' > x + 1]_x
=============================================================================
