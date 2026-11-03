---- MODULE spec ----
\* R4.2n: a `[]P` PROPERTY whose P is a bare operator name joins the
\* invariants under P's own name (`processConfigProps` OPCODE_box).
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 3 /\ x' = x + 1
Inv == x < 2
P == []Inv
====
