---- MODULE A ----
EXTENDS Sequences
Foo == SelectSeq(<<1, 2, 3>>, LAMBDA e : e = 1)
====
