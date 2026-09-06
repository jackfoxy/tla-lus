---- MODULE spec ----
\* R2.7.15b: an IMPLIED ACTION over a next-state relation WITH a stuttering
\* step. `[][A]_v` is `A \/ UNCHANGED v`, so the `x' = x` disjunct satisfies
\* it however `A` reads -- checking `A` alone reported a violation tlc2 does
\* not, on THIS engine as well as the BFS one. Every pre-existing
\* implied-action case has a next-state relation with no stuttering step,
\* which is why the bug was invisible in both.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == \/ x' = x
        \/ (x < 3 /\ x' = x + 1)
ActOk == [][x' = x + 1]_x
====
