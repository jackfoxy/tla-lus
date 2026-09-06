---- MODULE A ----
EXTENDS Integers
VARIABLE x
Init == x = 0
Next == x' = 1 - x
Live == <>FALSE
====
