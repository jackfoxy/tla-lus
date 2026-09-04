---- MODULE spec ----
EXTENDS Naturals
VARIABLES x, y

Init == x = 0 /\ y = 0

\* a multi-binder existential in ACTION position: tlc2 runs one
\* ContextEnumerator over both bound groups, the leading binder varying
\* fastest, so the successor ORDER (and with it the queue count and which
\* violation is reported first) depends on the odometer direction
Next == \E i \in 1..2, j \in 1..3 :
          /\ x' = i
          /\ y' = j

Spec == Init /\ [][Next]_<<x, y>>

Inv == x + y < 5
=====================
