---- MODULE spec ----
\* R2.7.14b: the CLOSING EDGE. A deterministic two-state back-to-state lasso,
\* so the counter-example graph is exactly 2 states and 2 actions -- one
\* forward edge and one edge closing the lasso -- and both endpoints are
\* pinned by state NUMBER. `gh1389-violc` pins the same shape, but its witness
\* varies at the pin; this one does not.
\*
\* Endpoints are compared as `a[1][1]` rather than against a record literal
\* on purpose: a record field named after a declared VARIABLE draws six lines
\* of SANY lint per occurrence, which would bury the assertion in the golden.
EXTENDS Naturals, FiniteSets, TLCExt
VARIABLE x
Init == x = 0
Next == x' = 1 - x
Spec == Init /\ [][Next]_x /\ WF_x(Next)
Live == <>[](x = 1)
PostCondition ==
    LET S == CounterExample.state
        A == CounterExample.action
    IN
    /\ Cardinality(S) = 2
    /\ Cardinality(A) = 2
    /\ \A s \in S : s[1] \in 1..2 /\ s[2].x = (s[1] - 1)
    /\ \A a \in A : a[2].name = "Next"
    /\ \E a \in A : a[1][1] = 1 /\ a[3][1] = 2
    /\ \E a \in A : a[1][1] = 2 /\ a[3][1] = 1
====
