---- MODULE spec ----
\* R2.7.6.3 probe: the same recursive shape as `live-witness-rec`, but the
\* property HOLDS. If the expanded leaf (the recursive CALL, evaluated as a
\* state predicate) is evaluated wrongly, this flips the VERDICT rather than
\* just the witness -- a stronger and deterministic check.
EXTENDS Naturals
VARIABLE x
RECURSIVE R(_)
R(n) == IF n = 0 THEN (x = 0) ELSE <>(R(n - 1))
Init == x = 0
Next == x' \in {0, 1}
Spec == Init /\ [][Next]_x /\ WF_x(Next)
Prop == R(1)
====
