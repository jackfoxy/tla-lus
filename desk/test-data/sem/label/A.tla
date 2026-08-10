---- MODULE A ----
EXTENDS Integers
Op(p) == \A x \in {1, 2} : lab(x) :: x + p
Simple == lab2 :: TRUE
====
