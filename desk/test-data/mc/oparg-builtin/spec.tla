---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Red(op(_, _), a, b) == op(a, b)
ASSUME Red(\intersect, {1, 2}, {2, 3}) = {2}
ASSUME Red(\union, {1}, {3}) = {1, 3}
Init == x = Red(\cup, {0}, {1})
Next == x' = Red(\cap, x, {1})
====
