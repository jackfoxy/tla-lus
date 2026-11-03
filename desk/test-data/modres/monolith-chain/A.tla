---- MODULE A ----
EXTENDS B
Foo == Bar
====
---- MODULE B ----
EXTENDS C
Bar == Qux
====
---- MODULE C ----
Qux == 2
====
