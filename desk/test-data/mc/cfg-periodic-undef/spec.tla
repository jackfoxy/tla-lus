---- MODULE spec ----
\* R2.7.7.2: `_PERIODIC` naming an operator that does not exist. tlc2
\* resolves the name at SPEC PROCESSING (SpecProcessor lines 944-948), before
\* a single state is computed -- unlike POSTCONDITION, which resolves after
\* exploration.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = 1 - x
Two(a) == a = 1
====
