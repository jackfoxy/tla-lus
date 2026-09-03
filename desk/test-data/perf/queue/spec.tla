---- MODULE A ----
\* Hot path: the BFS QUEUE. A 24x24 grid walked one axis at a time -- many
\* states carrying trivial values, so the cost is enqueue / dedup /
\* fingerprint-set membership rather than evaluation.
EXTENDS Integers
VARIABLES x, y
Init == x = 0 /\ y = 0
Next == \/ /\ x' = (x + 1) % 24
           /\ y' = y
        \/ /\ y' = (y + 1) % 24
           /\ x' = x
Inv  == x < 24 /\ y < 24
====
