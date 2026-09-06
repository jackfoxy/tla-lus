---- MODULE A ----
EXTENDS Integers
Dg(u) == 2 * u
A == Dg(5)!:
Dh == \A x \in {1} : x = 1
B == Dh!(2)!>>
Di == <<10, 20, 30>>
C == Di!:
====
