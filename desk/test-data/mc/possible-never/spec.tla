---- MODULE spec ----
\* R2.7.7.4b: `_POSSIBLE` witnesses. A state-level predicate is tracked as a
\* MODEL constraint (every discovered state) and an action-level one as an
\* ACTION constraint (every transition), which is how the pin wires them.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x + 1 /\ x < 3
Reached == x = 2
Moved == x' = x + 1
Never == x = 99
====
