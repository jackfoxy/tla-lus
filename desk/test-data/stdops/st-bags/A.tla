---- MODULE A ----
EXTENDS Bags, Integers
B == SetToBag({1, 2})
IsB == IsABag(B)
NotB == IsABag({1, 2})
CardB == BagCardinality(B)
InB == BagIn(1, B)
NotInB == BagIn(9, B)
Copies == CopiesIn(1, B)
Cup == B \oplus B
Diff == (B \oplus B) \ominus B
SqSub == B \sqsubseteq (B \oplus B)
ToSet == BagToSet(B)
Empty == EmptyBag
Subs == SubBag(B)
OfAll == BagOfAll(LAMBDA x : x + 1, B)
BUnion == BagUnion({B, B})
CopiesMissing == CopiesIn(9, B)
====
