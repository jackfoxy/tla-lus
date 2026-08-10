---- MODULE A ----
EXTENDS Integers
Op(Arg(_), p) == \A x \in {1, 2}, <<y, z>> \in {<<3, 4>>} : lab(x, y, z) :: Arg(1) + p + x + y + z
Foo(u) == 2 * u
Bar == Op(Foo, 9)!lab(1, 2, 3)
====
