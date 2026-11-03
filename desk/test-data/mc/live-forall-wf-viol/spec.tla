---- MODULE spec ----
\* R4.2n: the quantified fairness covers only p = 1, so p = 2 may stutter
\* forever and `Done` is violated; the per-element leaves must stay distinct.
EXTENDS Naturals
VARIABLE x
Init == x = [p \in 1..2 |-> 0]
Inc(p) == x[p] < 2 /\ x' = [x EXCEPT ![p] = x[p] + 1]
Next == (\E p \in 1..2 : Inc(p)) \/ UNCHANGED x
Spec == Init /\ [][Next]_x /\ \A p \in {1} : WF_x(Inc(p))
Done == <>(\A p \in 1..2 : x[p] = 2)
====
