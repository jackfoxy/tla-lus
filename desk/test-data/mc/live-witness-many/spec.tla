---- MODULE spec ----
\* R2.7.6.2 probe: the same shape as `live-witness` but with TEN successors,
\* so the port has a real choice among sound witnesses (1..8) as well as the
\* unsound one (9, which satisfies the promise and cannot be on a
\* counter-example).
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' \in 0..9
Spec == Init /\ [][Next]_x /\ WF_x(Next)
Prop == <>(x = 9)
====
