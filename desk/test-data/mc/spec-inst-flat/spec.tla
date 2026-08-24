---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
---- MODULE inner ----
EXTENDS Naturals
VARIABLE v
CONSTANT k
SpecI == (v = 0) /\ [][v' = (v + 1) % k]_v
====
I == INSTANCE inner WITH v <- x, k <- 3
Spec == I!SpecI
Inv == x < 9
====
