---- MODULE spec ----
\* R4.2n: fairness on an action whose ARGUMENT reads the state,
\* `WF_x(Up(p, x[p]))` (the allocator specs' `Return(c, alloc[c])`). The
\* solver evaluated such an argument with no current state; ENABLED read the
\* failure as FALSE, so the fairness was silently vacuous and `Done` was
\* reported violated. It holds.
EXTENDS Naturals
VARIABLE x
Init == x = [p \in 1..2 |-> 0]
Up(p, v) == v < 2 /\ x' = [x EXCEPT ![p] = v + 1]
Next == (\E p \in 1..2 : Up(p, x[p])) \/ UNCHANGED x
Spec == Init /\ [][Next]_x /\ \A p \in 1..2 : WF_x(Up(p, x[p]))
Done == <>(\A p \in 1..2 : x[p] = 2)
====
