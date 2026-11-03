---- MODULE spec ----
\* R4.2n: a refinement PROPERTY through an INSTANCE (`A!ASpec`), decomposed
\* through the substitution wrapper into an implied init, an implied action
\* and a fairness formula (YoYo/LockHS/AlternatingBit's shape).
EXTENDS Naturals
VARIABLE x
---- MODULE Abs ----
VARIABLE y
AInit == y \in {0, 1}
ANext == y' = 1 - y
ASpec == AInit /\ [][ANext]_y /\ WF_y(ANext)
====
Init == x = 0
Next == x' = (x + 1) % 4
Spec == Init /\ [][Next]_x /\ WF_x(Next)
A == INSTANCE Abs WITH y <- x % 2
Refines == A!ASpec
====
