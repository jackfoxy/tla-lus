---- MODULE A ----
EXTENDS Integers
All == \A x \in 1..3 : x > 0
AllF == \A x \in 1..3 : x > 1
Ex == \E x \in 1..5 : x * x = 16
ExF == \E x \in 1..3 : x = 9
Ch == CHOOSE x \in 1..10 : x * x = 25
Cond == IF 3 > 2 THEN "y" ELSE "n"
Cas == CASE 1 = 2 -> "a" [] 1 = 1 -> "b" [] OTHER -> "c"
====
