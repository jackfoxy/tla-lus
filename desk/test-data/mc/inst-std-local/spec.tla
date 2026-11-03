---- MODULE spec ----
\* R4.2v: a StandardModule reached through an instanced module's
\* `LOCAL INSTANCE FiniteSets` keeps its overrides: `Cardinality`'s vendored
\* body is a dummy with an unbounded CHOOSE (Disruptor's RingBuffer).
EXTENDS Naturals
---- MODULE Buf ----
LOCAL INSTANCE FiniteSets
CONSTANT Slots
Count == Cardinality(Slots)
====
VARIABLE x
B == INSTANCE Buf WITH Slots <- {1, 2, 3}
Init == x = 0
Next == x < B!Count /\ x' = x + 1
====
