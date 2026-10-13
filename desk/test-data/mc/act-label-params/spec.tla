---- MODULE spec ----
\* R4.2n: a trace step through a parametrized action is labelled with the
\* action operator's arguments, `<Inc(1) ...>` and `<Op(1,"a") ...>`
\* (`Action.getLocation`); the port printed `<Inc ...>`.
EXTENDS Naturals
VARIABLE x
Init == x = [p \in 1..2 |-> 0]
Inc(p) == x[p] < 2 /\ x' = [x EXCEPT ![p] = x[p] + 1]
Op(n, s) == x[1] = 2 /\ x[2] < 2 /\ s = "a" /\ x' = [x EXCEPT ![2] = x[2] + n]
Next == (\E p \in {1} : Inc(p)) \/ (\E s \in {"a"} : Op(1, s))
====
