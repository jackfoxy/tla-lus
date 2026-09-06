---- MODULE A ----
EXTENDS TLC, Integers, Sequences
AssertFalse == Assert(FALSE, "boom")
SortNotBool == SortSeq(<<1, 2>>, LAMBDA x, y : x)
SortNotSeq == SortSeq({1, 2}, LAMBDA x, y : x < y)
PermsNotSet == Permutations(3)
CombNotFcn == 1 @@ 2
AnyV == Any
====
