---- MODULE A ----
EXTENDS Integers
Mem == <<1, 1>> \in ((1..2) \X (1..2))
NotMem == <<9, 9>> \in ((1..2) \X (1..2))
Tri == <<1, 2, 3>> \in ({1} \X {2} \X {3})
====
