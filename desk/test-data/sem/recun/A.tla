---- MODULE A ----
EXTENDS Naturals
RECURSIVE F(_, _)
F(a, b) == IF b = 0 THEN 0 ELSE F(a, b - 1)
====
