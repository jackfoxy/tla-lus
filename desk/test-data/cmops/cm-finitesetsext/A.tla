---- MODULE A ----
EXTENDS Naturals, Sequences, FiniteSetsExt
FS == FoldSet(LAMBDA x, acc : x + acc, 0, {1, 2, 3})
FSSeq == FoldSet(LAMBDA x, acc : acc \o <<x>>, <<>>, {3, 1, 2})
FSStr == FoldSet(LAMBDA x, acc : acc \o <<x>>, <<>>, {"b", "a", "c"})
FSE == FoldSet(LAMBDA x, acc : x + acc, 7, {})
KS == kSubset(2, {1, 2, 3})
KS0 == kSubset(0, {1, 2})
KSBig == kSubset(4, {1, 2})
Q == Quantify({1, 2, 3, 4}, LAMBDA x : x > 2)
QE == Quantify({}, LAMBDA x : TRUE)
====
