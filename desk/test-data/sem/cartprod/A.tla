---- MODULE A ----
EXTENDS Integers
P == (1..2) \X (1..2)
Q == (1..2) \times (1..2)
T == {1} \X {2} \X {3}
Mem == <<1, 1>> \in ((1..2) \X (1..2))
Filt == {x \in ((1..2) \X (1..2)) : TRUE}
====
