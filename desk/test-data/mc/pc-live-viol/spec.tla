---- MODULE spec ----
\* R2.7.14: a POSTCONDITION runs after a TEMPORAL violation too. R2.7.7.3
\* wired postconditions into the clean and the safety-error reports and left
\* this path out entirely, so a false postcondition on a spec with a temporal
\* PROPERTY printed nothing at all. The line sits between the counter-example
\* and the counts.
EXTENDS Naturals, TLC
VARIABLE x
Init == x = 0
Next == x' = x
Live == <>(x = 1)
Post == TLCGet("distinct") = 999
====
