---- MODULE A ----
F(g(_,_), x) == g(x, x)
THEOREM L == ASSUME NEW op(_,_), NEW b
             PROVE  F(op, b) = op(b, b)
====
