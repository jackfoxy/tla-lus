---- MODULE A ----
EXTENDS Integers
VARIABLE x
Init == x = 0
Next == \/ x' = x
        \/ x' = 1
P1 == <>(x = 1)
P2 == []<>(x = 0)
====
