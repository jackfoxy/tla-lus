---- MODULE spec ----
\* R2.7.15: a level-1 PROPERTY is an IMPLIED INIT, checked while computing the
\* initial states -- so it pre-empts everything, including the temporal
\* property declared beside it, and prints NO state-graph counts.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == \/ x' = x
        \/ (x < 3 /\ x' = x + 1)
InitBad == x = 5
Live    == <>(x = 9)
====
