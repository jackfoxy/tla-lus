---- MODULE A ----
VARIABLE x
Apply(P(_)) == P(0)
Foo == Apply(LAMBDA y : y = x)
====
