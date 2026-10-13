---- MODULE spec ----
\* R4.2n: fairness quantified over a constant set (`\A p \in S : WF_v(A(p))`),
\* the shape of most Examples liveness specs. tlc2 expands it per element
\* (`Liveness.astToLiveAppl` OPCODE_bf); the port refused it (EC 2213).
EXTENDS Naturals
VARIABLE x
Init == x = [p \in 1..2 |-> 0]
Inc(p) == x[p] < 2 /\ x' = [x EXCEPT ![p] = x[p] + 1]
Next == (\E p \in 1..2 : Inc(p)) \/ UNCHANGED x
Spec == Init /\ [][Next]_x /\ \A p \in 1..2 : WF_x(Inc(p))
Done == <>(\A p \in 1..2 : x[p] = 2)
====
