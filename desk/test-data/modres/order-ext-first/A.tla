---- MODULE A ----
EXTENDS B
I == INSTANCE C WITH k <- 1
Foo == Bar + I!Baz
====
