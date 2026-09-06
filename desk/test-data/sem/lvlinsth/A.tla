---- MODULE A ----
VARIABLE x
Op(a) == x' = a
I == INSTANCE B WITH F <- Op
====
