---- MODULE spec ----
EXTENDS Naturals, FiniteSets
CONSTANT S
VARIABLE x
TC(R) ==
  LET N == Cardinality(S)
      trcl[n \in Nat] ==
        [a, b \in S |-> IF n = 0 THEN R[a, b]
                        ELSE \/ trcl[n-1][a, b]
                             \/ \E z \in S : trcl[n-1][a, z] /\ trcl[n-1][z, b]]
  IN  trcl[N]
Fact[n \in Nat] == IF n = 0 THEN 1 ELSE n * Fact[n - 1]
Edge == [p \in S \X S |-> p[2] = p[1] + 1]
ASSUME TC(Edge)[1, 3] /\ ~TC(Edge)[3, 1]
ASSUME Fact[5] = 120
Init == x = 0
Next == x < 3 /\ x' = Fact[x + 1]
Inv == x \in {0, 1, 2, 6}
====
