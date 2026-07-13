---- MODULE LivenessLasso ----
EXTENDS Naturals
VARIABLE n
Init == n = 0
Next == n' = (n + 1) % 3
Spec == Init /\ [][Next]_n /\ WF_n(Next)
Live == <>[](n = 0)
====
