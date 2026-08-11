---- MODULE A ----
RECURSIVE g(_)
foo == INSTANCE B WITH F <- g
Bar(x) == foo!Use(x)
g(n) == g(n)
====
