---- MODULE spec ----
\* R2.7.9: `-terse` suppresses the EXPANSION of some lazy sets when a state is
\* printed. Measured at the pin: `SUBSET (1..3)` and `(1..4) \X (1..2)` stay
\* unexpanded, while a set FILTER `{y \in 1..4 : y > 1}` is expanded anyway --
\* it is per-Value-class, not a global switch.
EXTENDS Naturals, FiniteSets
VARIABLE x
Init == x = SUBSET (1..3)
Next == UNCHANGED x
Inv == Cardinality(x) = 99
====
