---- MODULE A ----
EXTENDS Integers
F == [i \in 1..3 |-> i]
ExF == [F EXCEPT ![2] = 99]
ExAt == [F EXCEPT ![2] = @ + 100]
R == [a |-> 1, b |-> [c |-> 2]]
ExR == [R EXCEPT !.a = 5]
ExNest == [R EXCEPT !.b.c = 42]
T == <<1, 2, 3>>
ExT == [T EXCEPT ![3] = 30]
ExMulti == [F EXCEPT ![1] = 7, ![3] = 8]
====
