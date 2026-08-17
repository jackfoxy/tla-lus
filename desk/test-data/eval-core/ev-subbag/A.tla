---- MODULE A ----
EXTENDS Bags, Integers, FiniteSets
B == SetToBag({1, 2})
Subs == SubBag(B)
NSubs == Cardinality(SubBag(B))
Empty == SubBag(EmptyBag)
====
