---- MODULE spec ----
\* R4.2n: the implied-action part of a decomposed PROPERTY is violated on the
\* 3 -> 1 step; reported as tlc2 reports an action property.
EXTENDS Naturals
VARIABLE hr
HCini == hr \in 1..3
HCnxt == hr' = IF hr = 3 THEN 1 ELSE hr + 1
Up == HCini /\ [][hr' = hr + 1]_hr
====
