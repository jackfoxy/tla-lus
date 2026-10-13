---- MODULE spec ----
\* R4.2n: strong fairness quantified over a constant set. Each SF expands to
\* a disjunction, so the DNF distributes conjunctions of conjunctions;
\* `LNConj.addConj` splices them, and the port's unspliced product raised
\* EC 2214 (MultiCarElevator, the allocator specs).
EXTENDS Naturals
VARIABLE x
Init == x = [p \in 1..2 |-> 0]
Inc(p) == x[p] < 2 /\ x' = [x EXCEPT ![p] = x[p] + 1]
Next == (\E p \in 1..2 : Inc(p)) \/ UNCHANGED x
Spec == Init /\ [][Next]_x /\ \A p \in 1..2 : SF_x(Inc(p))
Done == \A p \in 1..2 : (x[p] = 0) ~> (x[p] = 2)
====
