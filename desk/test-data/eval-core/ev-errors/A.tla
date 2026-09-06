---- MODULE A ----
EXTENDS Integers
DivZero == 5 \div 0
BadDom == [i \in 1..3 |-> i][9]
====
