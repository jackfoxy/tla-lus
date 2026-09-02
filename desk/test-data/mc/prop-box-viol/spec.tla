---- MODULE spec ----
\* R2.7.15: `processConfigProps` routes EVERY property. A `[]P` box-state
\* PROPERTY joins the INVARIANT vector and a genuine temporal one goes to the
\* liveness engine, in the SAME run -- and the safety violation pre-empts the
\* temporal verdict exactly as an INVARIANT does (R2.3.4). Note the box-state
\* property is reported as an `Invariant`, not as a `Temporal property`.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == \/ x' = x
        \/ (x < 3 /\ x' = x + 1)
BoxBad  == [](x < 2)
Live    == <>(x = 9)
====
