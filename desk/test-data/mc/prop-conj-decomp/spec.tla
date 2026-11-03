---- MODULE spec ----
\* R4.2n: `processConfigProps` decomposes a PROPERTY through a definition
\* and `/\`: `HCini` is an implied init and `[][HCnxt]_hr` an implied action
\* (HourClock2's shape). The port binned the conjunction whole and refused it.
EXTENDS Naturals
VARIABLE hr
HCini == hr \in 1..3
HCnxt == hr' = IF hr = 3 THEN 1 ELSE hr + 1
HC == HCini /\ [][HCnxt]_hr
====
