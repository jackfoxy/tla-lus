---- MODULE A ----
Foo == \E <<y, z>> \in {<<1,2>>} : y = z
Bar == \A x \in {1}, <<y, z>> \in {<<3,4>>} : (x = y) /\ (y = z)
====
