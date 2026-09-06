---- MODULE DeadlockCounter ----
EXTENDS Naturals
VARIABLE n
Init == n = 0
Next == n < 3 /\ n' = n + 1
====
