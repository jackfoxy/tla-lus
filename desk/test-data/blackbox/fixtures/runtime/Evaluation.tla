---------------------------- MODULE Evaluation ----------------------------
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = (x + 1) \div (x - x)
Spec == Init /\ [][Next]_x
=============================================================================
