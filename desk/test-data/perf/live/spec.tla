---- MODULE A ----
\* Hot path: LIVENESS. The 8.2-8.6 tableau build and lasso search, a
\* different cost curve from the safety search.
EXTENDS Integers
VARIABLE x
Init == x = 0
Next == x' = (x + 1) % 12
Spec == Init /\ [][Next]_x /\ WF_x(Next)
Live == <>(x = 11)
====
