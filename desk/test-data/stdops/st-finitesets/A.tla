---- MODULE A ----
EXTENDS FiniteSets, Integers
Fin == IsFiniteSet({1, 2, 3})
FinEmpty == IsFiniteSet({})
Card == Cardinality({1, 2, 3})
CardDup == Cardinality({1, 1, 2})
CardEmpty == Cardinality({})
CardInterval == Cardinality(1..10)
CardSubset == Cardinality(SUBSET {1, 2, 3})
CardUnion == Cardinality(UNION {{1, 2}, {2, 3}})
CardNotSet == Cardinality(3)
FinNat == IsFiniteSet(Nat)
CardNat == Cardinality(Nat)
====
