---- MODULE A ----
VARIABLE x
Apply(P(_)) == P(0)
Next == Apply(LAMBDA y : y = x')
====
