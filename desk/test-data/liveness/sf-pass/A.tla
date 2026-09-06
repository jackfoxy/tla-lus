---- MODULE A ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Ay == x = 0 /\ x' = 1
By == x = 1 /\ x' = 0
Cy == x = 1 /\ x' = 2
Done == x = 2 /\ x' = 2
Next == Ay \/ By \/ Cy \/ Done
Spec == Init /\ [][Next]_x /\ WF_x(Ay) /\ WF_x(By) /\ SF_x(Cy)
Live == <>(x = 2)
====
