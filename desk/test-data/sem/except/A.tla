---- MODULE A ----
EXTENDS Naturals
VARIABLE f, g
E1 == [f EXCEPT ![1] = 2]
E2 == [f EXCEPT !.a = 3, ![2].b = 4]
E3 == [f EXCEPT ![1, 2] = 5]
E4 == [f EXCEPT ![1] = @ + 1]
E5 == [f EXCEPT ![1] = [g EXCEPT !.c = @]]
====
