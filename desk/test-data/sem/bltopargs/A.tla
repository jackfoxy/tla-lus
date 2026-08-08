---- MODULE A ----
EXTENDS Integers
Apply(a, Op(_, _), b) == Op(a, b)
Foo == Apply(1, +, 2)
Bar == Apply(1, \cup, 2)
====
