---- MODULE A ----
RECURSIVE g(_)
foo(n) == INSTANCE B WITH F <- g, c <- n
g(n) == IF n = 0 THEN 1 ELSE foo(n)!Use
====
