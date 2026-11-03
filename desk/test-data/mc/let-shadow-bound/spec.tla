---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
S == {[block |-> [type |-> "a"], sig |-> 1], [block |-> [type |-> "b"], sig |-> 2]}
Op(sb) == LET block == sb.block IN block.type
Init == x = "none"
Next == \E block \in S : x' = Op(block)
====
