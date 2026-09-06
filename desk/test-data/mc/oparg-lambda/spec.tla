---- MODULE spec ----
EXTENDS Naturals
VARIABLE x

\* an operator argument supplied by a LAMBDA rather than by name: SANY
\* synthesizes an OpDefNode and points an OpArgNode at it, so there is no
\* name to resolve
Pick(S, P(_)) == CHOOSE y \in S : P(y)

Init == x = Pick({1, 2, 3}, LAMBDA n : n > 2)
Next == UNCHANGED x
Spec == Init /\ [][Next]_x

Inv == x = 3
=====================
