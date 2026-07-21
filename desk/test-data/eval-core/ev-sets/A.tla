---- MODULE A ----
EXTENDS Integers, FiniteSets
U == {1, 2} \cup {2, 3}
I == {1, 2, 3} \cap {2, 3, 4}
D == {1, 2, 3} \ {2}
Sub == SUBSET {1, 2}
Big == UNION {{1}, {2, 3}}
Card == Cardinality({5, 5, 6, 7})
In == 2 \in {1, 2, 3}
Sq == {x * x : x \in 1..3}
Filt == {x \in 1..6 : x % 2 = 0}
====
