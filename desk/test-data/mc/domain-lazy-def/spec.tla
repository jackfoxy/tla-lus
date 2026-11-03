---- MODULE spec ----
EXTENDS Naturals
VARIABLE c
Big == [a : 0..1100, b : 0..1000]
Init == c \in {r \in Big : r.a + r.b = 2}
Next == c.a > 0 /\ c' = [c EXCEPT !.a = @ - 1, !.b = @ + 1]
Inv == c \in Big
====
