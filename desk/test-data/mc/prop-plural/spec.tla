---- MODULE spec ----
\* R2.7.12: the PLURAL form of TLC_TEMPORAL_PROPERTY_VIOLATED. Both
\* PROPERTIES fail on the same lasso (the only behavior stutters at x = 0),
\* so tlc2 reports BOTH: "Temporal properties P1 and P2 were violated."
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x
P1 == <>(x = 1)
P2 == <>(x = 2)
====
