---- MODULE spec ----
\* R4.2n: fairness on a LET-bodied action (MultiCarElevator's
\* `WF_Vars(CallElevator(p))`): the leaf is evaluated with the LET's
\* definitions in scope.
EXTENDS Naturals
VARIABLE x
Init == x = 0
A(p) == LET a == x + p
            b == a + 1
        IN x < 4 /\ x' = b - 1
Next == (\E p \in {1} : A(p)) \/ UNCHANGED x
Spec == Init /\ [][Next]_x /\ \A p \in {1} : WF_x(A(p))
Prop == <>(x = 4)
====
