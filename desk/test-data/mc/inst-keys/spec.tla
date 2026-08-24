---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
---- MODULE inner ----
EXTENDS Naturals
VARIABLE v
CONSTANT k
InitI == v = 0
NextI == v' = (v + 1) % k
====
I == INSTANCE inner WITH v <- x, k <- 3
Init2 == I!InitI
Next2 == I!NextI
Inv == x < 9
====
