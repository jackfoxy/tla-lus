---- MODULE A ----
EXTENDS Naturals
CONSTANT c
THEOREM ASSUME NEW CONSTANT d, c = 1 PROVE c + d = d + c
THEOREM Named == ASSUME c = 2 PROVE c = 2
====
