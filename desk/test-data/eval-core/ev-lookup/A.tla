---- MODULE A ----
EXTENDS Integers, Sequences
F == [i \in 1..3 |-> i + 10]
App == F[2]
Dom == DOMAIN F
R == [a |-> 1, b |-> 2]
Field == R.b
RDom == DOMAIN R
T == <<9, 8, 7>>
TApp == T[1]
TLen == Len(T)
====
