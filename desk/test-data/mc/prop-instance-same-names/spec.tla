---- MODULE spec ----
\* R4.2n: an unnamed INSTANCE substitutes the instanced module's variable BY
\* NAME (`x <- x`). Chasing that call-by-name binding re-read it forever: an
\* infinite recursion that exhausted the loom in one event and took the ship
\* down (MCAlternatingBit's shape).
EXTENDS Naturals
---- MODULE Abs ----
VARIABLE x
AInit == x \in 0..3
ANext == x' = (x + 1) % 4
AFair == WF_x(ANext)
ASpec == AInit /\ [][ANext]_x /\ AFair
====
VARIABLE x
Init == x = 0
Next == x' = (x + 1) % 4
Spec == Init /\ [][Next]_x /\ WF_x(Next)
INSTANCE Abs
====
