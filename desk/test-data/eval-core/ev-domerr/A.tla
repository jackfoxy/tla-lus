---- MODULE A ----
EXTENDS Integers, Sequences
F == [i \in 1..3 |-> i]
Lam == [i \in 1..3 |-> i][9]
Rcd == F[9]
NonInt == F["x"]
Tup == <<1, 2>>[5]
G == [x \in {"a", "b"} |-> 1]
GMiss == G["z"]
====
