---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 3 /\ x' = x + 1
Spec == Init /\ [][Next]_x
P == \A i \in {1, 2} : [](x < i + 1)
Q == \A i \in {2, 5} : <>(x = i)
R == \A i \in {1, 2} : x # i - 1
A == \A i \in {1, 2} : [][x' # i + 1]_x
====
