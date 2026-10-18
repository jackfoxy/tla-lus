---- MODULE spec ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Next == x < 3 /\ x' = x + 1
Spec == Init /\ [][Next]_x
Check(k, m) == [](x < k) /\ <>(x = m)
Prop == Check(2, 3)
Live(m) == <>(x = m)
P3 == Live(3)
====
