---- MODULE spec ----
\* R2.7.15: an IMPLIED ACTION that is VIOLATED alongside a violated temporal
\* property -- the action-property error (EC 2112) pre-empts the temporal
\* verdict, the same precedence a box-state property has.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = (x + 2) % 8
ActBad == [][x' = x + 1]_x
Live   == <>(x = 9)
====
