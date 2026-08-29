---- MODULE spec ----
\* upstream test-model/Github1389Violated.tla: the expanded property is
\* genuinely violated, so the recursion must reach the tableau and surface
\* as TLC_TEMPORAL_PROPERTY_VIOLATED rather than EC 2213.
EXTENDS Naturals
VARIABLE x
RECURSIVE Reach(_)
Reach(n) == IF n = 0 THEN <>(x = 99) ELSE Reach(n - 1)
Init == x = 0
Next == x' = 1 - x
Spec == Init /\ [][Next]_x /\ WF_x(Next)
PropViolated == Reach(3)
====
