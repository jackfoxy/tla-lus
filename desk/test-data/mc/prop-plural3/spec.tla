---- MODULE spec ----
\* R2.7.12: the three-or-more plural form, which uses a DIFFERENT separator
\* from the two-name one -- "P1, P2, and P3 were violated." against
\* "P1 and P2 were violated." (MP.java's TLC_TEMPORAL_PROPERTY_VIOLATED).
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x
P1 == <>(x = 1)
P2 == <>(x = 2)
P3 == <>(x = 3)
====
