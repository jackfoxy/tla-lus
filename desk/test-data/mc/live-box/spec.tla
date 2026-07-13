---- MODULE spec ----
EXTENDS Integers
VARIABLE x
Init == x = 0
Next == x' = 1 - x
Prop == []<>(x = 2)
====
