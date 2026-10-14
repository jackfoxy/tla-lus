---- MODULE spec ----
EXTENDS Naturals, TLC
B == RandomElement(0..99)
A == RandomElement(0..99)
D == B + 1000 * RandomElement(0..99)
E == A + B
VARIABLES x, y
Init == x = RandomElement(0..99) /\ y = <<A, B, D, E>>
Next == UNCHANGED <<x, y>>
Inv == x > 1000
ASSUME RandomElement(0..99) >= 0
====
