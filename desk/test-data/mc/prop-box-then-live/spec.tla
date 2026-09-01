---- MODULE spec ----
\* R2.7.12 measured this and did NOT fix it. A []P box-state PROPERTY
\* FOLLOWED by a genuine temporal one: SpecProcessor.processConfigProps
\* routes EVERY property (box-state to the invariant vector, level-1 to the
\* implied inits, [][A]_v to the implied actions, the rest to the liveness
\* engine), and the port routes on the FIRST property alone -- so P2 is
\* never checked and the port completes clean where tlc2 reports P2.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == \/ x' = x
        \/ (x < 3 /\ x' = x + 1)
P1 == [](x < 9)
P2 == <>(x = 3)
====
