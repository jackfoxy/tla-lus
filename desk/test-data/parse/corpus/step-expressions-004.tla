---- MODULE Test ----
Prop == [][x = {1, 2}]_x
Prop == [][1 \in {1, 2}]_x
Prop == [][LET S == {1, 2} IN x \in S]_x
Prop == [][LET S == {1, 2} IN x \in {1, 2}]_x
Prop == [][TRUE /\ x \in {1, 2}]_x
====
