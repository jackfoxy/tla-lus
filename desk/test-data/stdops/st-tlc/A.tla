---- MODULE A ----
EXTENDS TLC, Integers, Sequences
CONSTANT MS
Single == 1 :> "a"
Comb == (1 :> "a") @@ (2 :> "b")
CombLeft == (1 :> "a") @@ (1 :> "b")
Str == ToString(42)
StrSet == ToString({1, 2})
StrSeq == ToString(<<1, "a">>)
Perms == Permutations(MS)
Sort == SortSeq(<<3, 1, 2>>, LAMBDA x, y : x < y)
SortEmpty == SortSeq(<<>>, LAMBDA x, y : x < y)
Ok == Assert(TRUE, "never printed")
Pr == Print("printed value", 7)
PrT == PrintT("printed alone")
====
