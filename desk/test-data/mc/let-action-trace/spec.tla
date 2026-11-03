---- MODULE spec ----
\* R4.2n: an action whose body is a LET with sibling definitions. `+get-actions`
\* descended through the LET and dropped its definitions, so `x' = b - 1`
\* failed "undefined operator: b". The trace label is the LET BODY's location.
EXTENDS Naturals
VARIABLE x
Init == x = 0
A(p) == LET a == x + p
            b == a + 1
        IN x < 3 /\ x' = b - 1
Next == \E p \in {1} : A(p)
====
