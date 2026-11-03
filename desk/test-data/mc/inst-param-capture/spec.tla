---- MODULE spec ----
EXTENDS Naturals, Sequences, FiniteSets
---- MODULE Inner ----
EXTENDS Naturals, Sequences, FiniteSets
Succ(state) == state + 1
SeqToSet(seq) == {seq[i] : i \in 1..Len(seq)}
VARIABLES state, i
vars == <<state, i>>
Init == state = 0 /\ i = 7
Next == \/ /\ state < 3
           /\ state' = Succ(state + 10) - 10
           /\ i' = Cardinality(SeqToSet(<<state, state>>)) + 3
        \/ state = 3 /\ UNCHANGED vars
====
VARIABLES state, i
INSTANCE Inner
====
