---- MODULE A ----
VARIABLE x
Op(a) == a' = x
I == INSTANCE B WITH c <- x', F <- Op
====
