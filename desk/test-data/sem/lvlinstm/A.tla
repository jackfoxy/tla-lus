---- MODULE A ----
VARIABLE x
Op(a) == a' = x
I == INSTANCE B WITH y <- x, F <- Op
====
