---- MODULE A ----
EXTENDS Integers
VARIABLE x
THEOREM Thm1 == x \in 0..3
Init == Thm1!:
Inv == Thm1!<<
Inv2 == Thm1!>>
THEOREM Thm1b == x = 1 /\ x < 3
Prop == Thm1b!2!1
====
