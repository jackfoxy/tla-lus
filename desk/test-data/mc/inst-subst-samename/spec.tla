---- MODULE spec ----
EXTENDS Naturals
---- MODULE Cons ----
CONSTANT Value
VARIABLE chosen
Init == chosen = {}
Next == chosen = {} /\ \E v \in Value : chosen' = {v}
Spec == Init /\ [][Next]_chosen
====
CONSTANT Value
VARIABLE x
chosen == IF x = 0 THEN {} ELSE {x}
Init == x = 0
Next == x = 0 /\ x' \in Value
C == INSTANCE Cons
Prop == C!Spec
====
