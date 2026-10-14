---- MODULE B ----
EXTENDS Naturals
CONSTANT Q
QNonEmpty == \A q \in Q : q # {}
Pos(n) == n > 0 /\ n < 10
====
