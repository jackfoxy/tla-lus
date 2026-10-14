---- MODULE spec ----
EXTENDS Naturals, TLC
VARIABLE x
Init == x = Print(<<"chosen", 3>>, 3)
Next == UNCHANGED x
ASSUME \/ \E i \in 1..5 : IF i > 2 THEN PrintT(i) ELSE FALSE
       \/ PrintT("No solution")
ASSUME \A i \in 1..3 : PrintT(<<"all", i>>) /\ i < 2
====
