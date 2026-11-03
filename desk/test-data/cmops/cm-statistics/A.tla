---- MODULE A ----
EXTENDS Naturals, Statistics
CSPass == ChiSquare([i \in 1..2 |-> 50], [i \in 1..2 |-> 50], "0.05")
CSFail == ChiSquare([i \in 1..2 |-> 50], <<90, 10>>, "0.05")
====
