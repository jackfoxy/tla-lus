---- MODULE A ----
EXTENDS Naturals
Ap(F(_), x) == F(x)
RECURSIVE R(_)
R(n) == IF n = 0 THEN 0 ELSE Ap(R, n - 1)
====
