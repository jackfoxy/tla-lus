---- MODULE spec ----
\* R2.7.15: the same two properties in the OPPOSITE order. tlc2's routing is
\* order-independent -- each property is binned on its own shape -- so the
\* verdict is identical to `prop-box-viol`. The port routed on the HEAD of the
\* list, which made these two cases disagree.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == \/ x' = x
        \/ (x < 3 /\ x' = x + 1)
Live   == <>(x = 9)
BoxBad == [](x < 2)
====
