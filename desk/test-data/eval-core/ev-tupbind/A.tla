---- MODULE A ----
EXTENDS Integers
S == (1..2) \X (1..2)
ExT == \E <<i, j>> \in S : i = j
AllT == \A <<i, j>> \in S : i <= j
FiltT == {<<i, j>> \in S : i = j}
MapT == {i + j : <<i, j>> \in S}
ChT == CHOOSE <<i, j>> \in S : i = j
FcnT == [<<i, j>> \in S |-> i * 10 + j]
====
