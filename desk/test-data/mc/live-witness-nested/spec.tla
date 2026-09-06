---- MODULE spec ----
\* R2.7.6.2 probe (nested eventualities), reduced from upstream Github1389ViolatedC: the property is
\* violated, and the counter-example must AVOID the witness value -- a lasso
\* through x = 99 satisfies <>(x = 99) and is not a counter-example at all.
\* The only sound loop value here is 5.
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x' \in {0, 5, 99}
Spec == Init /\ [][Next]_x /\ WF_x(Next)
Prop == <><><>(x = 99)
====
