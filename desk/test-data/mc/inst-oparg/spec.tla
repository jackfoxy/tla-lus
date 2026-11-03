---- MODULE spec ----
\* R4.2o: CONSTANT operators substituted through an INSTANCE by operators
\* (`$OpArg`; TwoPhase's `XInit(_)`, `XAct(_, _, _)`): the instanced action
\* `XAct(0, x, x')` expands the substituted operator, so `x'` is assigned.
EXTENDS Naturals
---- MODULE Two ----
CONSTANT XInit(_), XAct(_, _, _)
VARIABLE p, x
Init == p = 0 /\ XInit(x)
Next == p < 2 /\ XAct(p, x, x') /\ p' = p + 1
====
XInit(v) == v = 0
XAct(i, xInit, xNext) == xNext = xInit + i
VARIABLES p, x
INSTANCE Two
====
