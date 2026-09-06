---- MODULE A ----
\* Hot path: the EVALUATOR. The state graph is a line, so almost all the time
\* is +eval over a nested arithmetic/boolean invariant re-solved per state.
EXTENDS Integers
VARIABLE x
Init == x = 0
Next == x < 40 /\ x' = x + 1
Heavy(n) == ((n * n) + (n * 3) - 1) % 7
Inv == /\ Heavy(x) >= 0
       /\ Heavy(x + 1) >= 0
       /\ Heavy(x + 2) >= 0
       /\ \A i \in 1..12 : Heavy(x + i) >= 0
====
