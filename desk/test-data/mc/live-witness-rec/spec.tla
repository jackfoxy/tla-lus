---- MODULE spec ----
\* R2.7.6.2 probe: `live-witness-nested-many` with the nested eventualities
\* reached through RECURSIVE OPERATOR EXPANSION instead of written literally
\* -- the one structural difference left between the passing probes and
\* upstream's Github1389ViolatedC.
EXTENDS Naturals
VARIABLE x
RECURSIVE Reach(_)
Reach(n) == IF n = 0 THEN (x = 9) ELSE <>(Reach(n - 1))
Init == x = 0
Next == x' \in 0..9
Spec == Init /\ [][Next]_x /\ WF_x(Next)
Prop == Reach(3)
====
