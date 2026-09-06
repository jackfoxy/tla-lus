---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' = x + 1
Small == x < 10
NotThree == x # 3
====
