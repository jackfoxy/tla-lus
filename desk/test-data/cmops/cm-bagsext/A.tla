---- MODULE A ----
EXTENDS Naturals, Bags, BagsExt
FB == FoldBag(LAMBDA x, y : x + y, 0, SetToBag({1, 2, 3}))
FBC == FoldBag(LAMBDA x, y : x + y, 0, (SetToBag({1, 2}) (+) SetToBag({2})))
====
