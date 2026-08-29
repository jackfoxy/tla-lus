---- MODULE spec ----
\* upstream test-model/Github1389Loops.tla: the expansion does NOT reach a
\* base case (the guard is FALSE and the ELSE re-invokes with the same
\* argument). tlc2 overflows the JVM stack and reports EC 1005.
VARIABLE x
RECURSIVE bad(_)
bad(u) == IF u THEN [][TRUE]_x ELSE bad(u)
Spec == x = TRUE /\ [][x' = ~x]_x
Prop == bad(FALSE)
====
