---- MODULE spec ----
\* upstream test-model/Github1389StateGuard.tla: the recursive operator's
\* parameter is bound to a state variable, so the IF guard never resolves
\* during tableau construction and the expansion does not terminate.
EXTENDS Naturals
VARIABLE x
RECURSIVE op(_)
op(n) == IF n = 0 THEN <>(x = 0) ELSE op(n - 1)
Init == x = 0
Next == x' \in 0..3
Spec == Init /\ [][Next]_x
Prop == op(x)
====
