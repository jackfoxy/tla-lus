---- MODULE A ----
Op(a, b) == a
Bad == Op(1)
Quant == \A x \in {1, 2} : Op(x)
Unb == \E y : Op(y)
====
