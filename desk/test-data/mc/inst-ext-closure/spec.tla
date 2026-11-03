---- MODULE spec ----
\* R4.2o: `INSTANCE M` brings what M EXTENDS. The root does not extend
\* Naturals; the instanced module does, and its body uses `%` and `+`
\* (TwoPhase under MCTwoPhase).
---- MODULE Counter ----
EXTENDS Naturals
VARIABLE n
CInit == n = 0
CNext == n' = (n + 1) % 3
====
VARIABLE n
INSTANCE Counter
Inv == CInit \/ n \in {1, 2}
====
