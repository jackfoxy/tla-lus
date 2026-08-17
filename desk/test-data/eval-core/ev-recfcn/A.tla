---- MODULE A ----
EXTENDS Integers, FiniteSets
Fact[n \in 0..5] == IF n = 0 THEN 1 ELSE n * Fact[n - 1]
F5 == Fact[5]
FDom == DOMAIN Fact
Card[s \in SUBSET (1..3)] == IF s = {} THEN 0 ELSE 1 + Card[s \ {CHOOSE y \in s : TRUE}]
C3 == Card[{1, 2, 3}]
Even[n \in 0..4] == IF n = 0 THEN TRUE ELSE ~Even[n - 1]
E3 == Even[3]
====
