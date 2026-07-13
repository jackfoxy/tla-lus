---- MODULE spec ----
VARIABLES a, b
Init == a = FALSE /\ b = FALSE
Next == \/ a' = ~a /\ b' = b
        \/ b' = ~b /\ a' = a
Inv == TRUE
====
