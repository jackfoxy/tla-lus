---- MODULE spec ----
\* R2.7.7.5: `_PERIODIC` is evaluated by tlc2's PERIODIC-WORK THREAD, which is
\* driven by a wall-clock timer (`AbstractChecker` waits, then calls
\* `doPeriodicWork`), not by the search. On a spec this small the timer never
\* fires, so an always-FALSE `_PERIODIC` has NO effect and the run completes.
\* On a long-running spec the same config stops the run at whatever point the
\* timer happens to fire -- measured twice at the pin: 1 677 194 states in one
\* run and 1 740 872 in the next.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x + 1 /\ x < 3
Falsehood == FALSE
====
