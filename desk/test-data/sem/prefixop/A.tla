---- MODULE A ----
VARIABLE x
BoxTest(-._) == -(x=0)
-. a == {a}
a ^+ == {a}
SetOpTest(Foo(_)) == Foo({x})
UseSubset == SetOpTest(SUBSET)
UseNeg == SetOpTest(-.)
UsePost == SetOpTest(^+)
UseBoxOp == BoxTest([])
====
