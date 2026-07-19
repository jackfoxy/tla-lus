---- MODULE A ----
VARIABLE x
E1 == ENABLED (x' = x)
E2 == ENABLED ((x ~> x))
U1 == UNCHANGED x
U2 == UNCHANGED (x')
====
