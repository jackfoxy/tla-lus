---- MODULE spec ----
\* R4.2n: a PROPERTY quantified over a constant set, `\A p \in S : <>P(p)`
\* (LiveHourClock's `AllTimes` shape), expanded by the liveness converter.
EXTENDS Naturals
VARIABLE x
Init == x = [p \in 1..2 |-> 0]
Inc(p) == x[p] < 2 /\ x' = [x EXCEPT ![p] = x[p] + 1]
Next == (\E p \in 1..2 : Inc(p)) \/ UNCHANGED x
Spec == Init /\ [][Next]_x /\ \A p \in 1..2 : WF_x(Inc(p))
AllReach == \A p \in 1..2 : <>(x[p] = 2)
====
