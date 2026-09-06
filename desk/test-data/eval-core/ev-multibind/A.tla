---- MODULE A ----
EXTENDS Integers
G == [i \in 1..2, j \in 1..2 |-> i * 10 + j]
GAt == G[1, 2]
GDom == DOMAIN G
H == [i, j \in 1..2 |-> i + j]
ExMulti == \E i \in 1..3, j \in 1..3 : i + j = 5
AllMulti == \A i \in 1..2, j \in 1..2 : i + j > 1
ExTup == \E <<i, j>> \in (1..2) \X (1..2) : i = j
SetMulti == {i * j : i \in 1..2, j \in 1..3}
====
