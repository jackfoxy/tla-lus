---- MODULE A ----
EXTENDS Naturals
RECURSIVE Even(_), Odd(_)
Even(n) == IF n = 0 THEN TRUE ELSE Odd(n - 1)
Odd(n) == IF n = 0 THEN FALSE ELSE Even(n - 1)
====
