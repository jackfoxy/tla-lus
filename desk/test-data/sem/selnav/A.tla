---- MODULE A ----
EXTENDS Integers
Da == <<10, 20, 30>>
A == Da!2
Db == 1 + 5
B == Db!<<
C == Db!>>
Dc == {1, 2, 3}
D == Dc!2
Dd == 3 + (4 + 7)
E == Dd!>>!<<
Df == [i \in 1..10 |-> i + 1][3]
G == Df!<<
====
