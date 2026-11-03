---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Ok(Q) == \E c \in {1, 2} : c > 0
Ok2 == \E c \in {1, 2} : c > 0
Init == x = 0
Next == x < 2 /\ Ok2 /\ x' = x + 1
====
