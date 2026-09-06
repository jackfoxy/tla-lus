---- MODULE A ----
EXTENDS Integers
VARIABLE x
Init == x = 0
Next == \/ x' = x
        \/ x' = 1
Live == <>(x = 1)
====
