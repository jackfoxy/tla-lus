---- MODULE spec ----
\* R4.2n: a property reached through TWO instances (glowingRaccoon's
\* `stagesInstance!primerDepleted == cleanInstance!primerDepleted`). The
\* nested member `M!L!Reach` was never generated, so `M!P` named nothing.
EXTENDS Naturals
---- MODULE Mid ----
VARIABLE m
---- MODULE Low ----
VARIABLE l
Reach == <>(l = 3)
====
L == INSTANCE Low WITH l <- m
P == L!Reach
====
VARIABLE x
Init == x = 0
Next == (x < 3 /\ x' = x + 1) \/ UNCHANGED x
Spec == Init /\ [][Next]_x /\ WF_x(Next)
M == INSTANCE Mid WITH m <- x
Prop == M!P
====
