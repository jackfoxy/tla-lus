---- MODULE A ----
CONSTANT z
Foo == LET a == z
           b == a
       IN b
====
