---- MODULE spec ----
\* R4.2p: UNCHANGED of a DEFINITION naming variables (`UNCHANGED rest`) and
\* of a NESTED tuple assigns every variable it names; both left variables
\* unassigned ("incomplete next state", 8 Examples rows).
EXTENDS Naturals
VARIABLES x, y, z
rest == <<y, z>>
Init == x = 0 /\ y = 1 /\ z = 2
Next == \/ x < 2 /\ x' = x + 1 /\ UNCHANGED rest
        \/ x = 2 /\ z' = 3 /\ UNCHANGED <<x, <<y>>>>
====
