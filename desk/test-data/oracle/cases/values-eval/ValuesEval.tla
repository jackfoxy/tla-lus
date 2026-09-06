---- MODULE ValuesEval ----
EXTENDS Naturals, Sequences, FiniteSets, TLC
VARIABLE x
ASSUME PrintT(<<"set", {3, 1, 2}>>)
ASSUME PrintT(<<"subset", SUBSET {1, 2}>>)
ASSUME PrintT(<<"fun", [i \in 1..3 |-> i * i]>>)
ASSUME PrintT(<<"rec", [a |-> 1, b |-> {2}]>>)
ASSUME PrintT(<<"seq", Append(<<1, 2>>, 3)>>)
ASSUME PrintT(<<"card", Cardinality({1, 2, 3})>>)
Init == x = 0
Next == x' = x
====
