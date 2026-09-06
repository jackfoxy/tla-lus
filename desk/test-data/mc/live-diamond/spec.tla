---- MODULE spec ----
EXTENDS Integers
VARIABLE x
Init == x = 0
Next == \/ x' = x
        \/ x' = 1
Prop == <>(x = 1)
====
