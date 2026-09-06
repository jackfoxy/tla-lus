---- MODULE spec ----
\* R2.7.14: on a CLEAN temporal run a failing POSTCONDITION REPLACES
\* `Model checking completed. No error has been found.` rather than being
\* appended to it -- the same rule R2.7.7.3 measured on the safety path,
\* since the error IS the run's outcome.
EXTENDS Naturals, TLC
VARIABLE x
Init == x = 0
Next == x' = 1 - x
Live == <>(x = 0)
Post == TLCGet("distinct") = 999
====
