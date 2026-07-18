---- MODULE A ----
VARIABLE x
B1 == [](x' = x)
E1 == <>(x' = x)
L1 == (x' = x) ~> TRUE
M1 == (x' = x) /\ []TRUE
Q1 == \E i \in {x'} : []TRUE
====
