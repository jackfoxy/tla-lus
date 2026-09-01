---- MODULE spec ----
\* R2.7.12: POST-HOC PROPERTY ATTRIBUTION. Two PROPERTIES; the FIRST one
\* HOLDS on the counter-example and the SECOND is the violated one, so the
\* reported name cannot come from the property list's head. tlc2 names it by
\* evaluating each declared property over the finished lasso
\* (Liveness.findViolatedProperties / LiveExprNode.evalOnLasso).
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == \/ x' = x
        \/ (x < 3 /\ x' = x + 1)
P1 == []<>(x < 9)
P2 == <>(x = 3)
====
