---- MODULE A ----
VARIABLE x
RECURSIVE R(_)
Bad == (x')'
R(a) == R(a)
====
