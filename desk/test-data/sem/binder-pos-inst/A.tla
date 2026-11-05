---- MODULE A ----
Id(x) == x
I == INSTANCE B WITH Op <- Id
F == \E i \in {1} : Id(i) = 1
====
