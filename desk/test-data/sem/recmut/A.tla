---- MODULE A ----
VARIABLE x
RECURSIVE P(_), Q(_)
P(n) == Q(n)
Q(n) == x' = n
====
