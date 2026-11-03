---- MODULE spec ----
EXTENDS Naturals
VARIABLES up, leader, log
Node == {1, 2, 3}
COW(src, dst) == up[src] /\ up[dst]
Con(src, dst) == COW(src, dst) /\ COW(dst, src)
Init == up = [n \in Node |-> TRUE] /\ leader = 1 /\ log = 0
Send(p) == /\ leader /= p
           /\ Con(leader, p)
           /\ log' = log + p
           /\ UNCHANGED <<up, leader>>
Fail(n) == up[n] /\ up' = [up EXCEPT ![n] = FALSE] /\ UNCHANGED <<leader, log>>
Next == (\E p \in Node : Send(p)) \/ (\E n \in Node : Fail(n))
Constr == log < 6
====
