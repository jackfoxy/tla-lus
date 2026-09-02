---- MODULE spec ----
\* R2.7.15c: an implied init that HOLDS, declared beside a genuine temporal
\* property that FAILS. tlc2 warns, checks the implied init while computing the
\* initial states, and carries on into the liveness engine.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x
InitOk == x = 0
Live   == <>(x = 9)
====
