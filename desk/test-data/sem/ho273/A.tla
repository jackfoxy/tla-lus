---- MODULE A ----
VARIABLE x
H(F(_), a) == F(a)
Pr(e) == e'
Bad == H(Pr, x')
Bad2 == H(Pr, x)
====
