---- MODULE spec ----
\* R2.7.14: the ORDER, measured. A stuttering counter-example under a
\* SPECIFICATION with no fairness prints the EC 2259 hint, and the
\* POSTCONDITION line comes AFTER that hint and BEFORE the counts:
\*   counter-example / closer / hint / postcondition / statistics.
EXTENDS Naturals, TLC
VARIABLE x
Init == x = 0
Next == \/ x' = x
        \/ (x < 3 /\ x' = x + 1)
Spec == Init /\ [][Next]_x
Live == <>[](x = 3)
Post == TLCGet("distinct") = 999
====
