---- MODULE A ----
EXTENDS Naturals
RECURSIVE Fact(_)
Fact(n) == IF n = 0 THEN 1 ELSE Fact(n - 1)
RECURSIVE Odd(_), Even(_)
Odd(n) == IF n = 0 THEN FALSE ELSE Even(n - 1)
Even(n) == IF n = 0 THEN TRUE ELSE Odd(n - 1)
====
