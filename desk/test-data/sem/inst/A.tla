---- MODULE A ----
VARIABLE x
I == INSTANCE B WITH y <- x, c <- 3
Use == I!Op
====
