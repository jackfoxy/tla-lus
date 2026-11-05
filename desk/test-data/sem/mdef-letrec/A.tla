---- MODULE A ----
P == LET RECURSIVE r(_)
        a == r(1)
        r(n) == n IN a
====
