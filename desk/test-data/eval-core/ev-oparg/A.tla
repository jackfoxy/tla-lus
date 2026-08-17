---- MODULE A ----
EXTENDS Integers, Sequences
Inc(n) == n + 1
Apply(Op(_), x) == Op(x)
Twice(Op(_), x) == Op(Op(x))
Fold(Op(_,_), a, b) == Op(a, b)
A1 == Apply(Inc, 5)
A2 == Twice(Inc, 5)
A3 == Apply(LAMBDA n : n * 2, 7)
A4 == Fold(LAMBDA a, b : a + b, 3, 4)
Sel == SelectSeq(<<1, 2, 3, 4>>, LAMBDA n : n % 2 = 0)
====
