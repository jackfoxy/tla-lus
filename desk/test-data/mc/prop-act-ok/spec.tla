---- MODULE spec ----
\* R2.7.15: an IMPLIED ACTION `[][A]_v` that HOLDS, declared FIRST, with a
\* violated temporal property after it. The port routed on the head of the
\* list, so the temporal property was never checked and the run completed
\* clean where tlc2 reports it.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == \/ x' = x
        \/ (x < 3 /\ x' = x + 1)
ActOk == [][x' = x + 1]_x
Live  == <>(x = 9)
====
