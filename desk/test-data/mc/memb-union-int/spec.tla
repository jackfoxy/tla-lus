---- MODULE spec ----
EXTENDS Integers
CONSTANT NULL
VARIABLE r
Init == r = [s |-> [i \in 0..1 |-> NULL]]
Next == \E i \in 0..1, v \in {-1, 2} : r' = [r EXCEPT !.s[i] = v]
TypeOk == r \in [s : UNION {[0..1 -> Int \cup {NULL}]}]
ASSUME NULL \notin Int
====
