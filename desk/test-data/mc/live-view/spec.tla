---- MODULE spec ----
\* R4.2e: VIEW with a temporal PROPERTY. States are identified by the VIEW's
\* value in the graph, so the liveness product must key a successor the same
\* way; it recomputed the plain fingerprint and was refused for that reason.
EXTENDS Naturals
VARIABLES x, t
Init == x = 0 /\ t = 0
Next == \/ x < 3 /\ x' = x + 1 /\ t' = t + 1
        \/ x = 3 /\ x' = 0 /\ t' = t + 1
Spec == Init /\ [][Next]_<<x, t>> /\ WF_<<x, t>>(Next)
View == x
Back == []<>(x = 0)
====
