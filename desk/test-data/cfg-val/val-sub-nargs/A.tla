---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Foo == 1
Bar(a) == a
Init == x = Foo
Next == x' = x + 1
====
