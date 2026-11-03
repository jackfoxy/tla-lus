---- MODULE A ----
EXTENDS B
I == INSTANCE C WITH k <- 1
Foo == Bar + I!Baz
====

---- MODULE B ----
EXTENDS Naturals
Bar == 1
====

---- MODULE C ----
CONSTANT k
Baz == k
====
