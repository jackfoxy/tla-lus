---- MODULE spec ----
\* R2.7.7.0: a POSTCONDITION naming an operator that does not exist. tlc2
\* rejects this at SPEC PROCESSING, before a single state is computed; the
\* port runs the spec to completion.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = 1 - x
====
