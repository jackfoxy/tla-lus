---- MODULE spec ----
EXTENDS Naturals
VARIABLES now, hr
NowNext == now' = (now + 1) % 3 /\ UNCHANGED hr
HCnxt == hr' = (hr + 1) % 2
Init == now = 0 /\ hr = 0
Next == /\ [NowNext]_now
        /\ [HCnxt]_hr
====
