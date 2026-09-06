---- MODULE spec ----
EXTENDS Naturals, TLC
VARIABLE x
Init == x = RandomElement(0..99)
Next == UNCHANGED x
Inv == x < 30
====
