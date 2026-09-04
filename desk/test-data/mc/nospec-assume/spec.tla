---- MODULE spec ----
EXTENDS Naturals, FiniteSets

CONSTANT N

\* a module with no VARIABLES and a config with no behaviour spec: TLC
\* checks the assumptions and completes over zero initial states. The
\* documented idiom for using TLC to evaluate expressions
ASSUME N \in Nat
ASSUME Cardinality({1, 2, 3}) = 3
ASSUME \A i \in 1..N : i * i >= i
=====================
