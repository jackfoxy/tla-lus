---- MODULE spec ----
\* R4.2: every argument is evaluated in the CALLER's env. `F`'s formal is
\* named `q`, like the bound variable its later argument reads; binding the
\* formals one by one and evaluating `Len(q) + 1` after the first made it
\* see the formal (N-Queens: "index 3 of tuple <<1, 1>>").
EXTENDS Naturals, Sequences
F(q, n) == q[n]
VARIABLE x
Init == x = 0
Next == /\ x = 0
        /\ \E q \in {<<5, 6>>} : x' = F(Append(q, 7), Len(q) + 1)
Inv == x \in {0, 7}
====
