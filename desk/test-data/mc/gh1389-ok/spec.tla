---- MODULE spec ----
\* upstream test-model/Github1389.tla (issue #1389): RECURSIVE operators
\* whose body reaches temporal level, expanded by Liveness.astToLive with
\* only the constant-guard IF branch translated. Three shapes: a boolean
\* guard, a numeric guard walked down to 0, and the recursion in THEN.
EXTENDS Naturals
VARIABLE x
RECURSIVE ap_0(_)
ap_0(u) == IF u THEN <>(x = TRUE) ELSE ap_0(~u)
RECURSIVE ap_2(_)
ap_2(n) == IF n = 0 THEN <>(x = TRUE) ELSE ap_2(n - 1)
RECURSIVE ap_3(_)
ap_3(n) == IF n > 0 THEN ap_3(n - 1) ELSE <>(x = TRUE)
Spec == x = TRUE /\ [][x' = ~x]_x
PropIf      == ap_0(TRUE)
PropDepth   == ap_2(3)
PropElseRec == ap_3(3)
====
