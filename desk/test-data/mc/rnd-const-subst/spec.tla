---- MODULE spec ----
EXTENDS Naturals, TLC
CONSTANT C
R == RandomElement(0..9)
VARIABLE x
Init == x = 100 + R
Next == x' = IF C = R THEN 200 ELSE C
====
