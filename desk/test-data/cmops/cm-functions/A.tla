---- MODULE A ----
EXTENDS Naturals, Sequences, Functions
Inj == IsInjective(<<1, 2, 3>>)
InjNo == IsInjective(<<1, 2, 1>>)
InjRec == IsInjective([a |-> 1, b |-> 2])
InjEmpty == IsInjective(<<>>)
Anti == AntiFunction(<<"a", "b">>)
AntiFn == AntiFunction([x \in {1, 2} |-> x * 10])
FF == FoldFunction(LAMBDA x, acc : acc * 10 + x, 0, <<1, 2, 3>>)
FFSum == FoldFunction(LAMBDA x, acc : x + acc, 0, [i \in 1..4 |-> i * i])
FFS == FoldFunction(LAMBDA x, acc : acc \o <<x>>, <<>>, <<3, 1, 2>>)
FFOS == FoldFunctionOnSet(LAMBDA x, acc : acc \o <<x>>, <<>>, <<5, 6, 7>>, {1, 3})
FFOSE == FoldFunctionOnSet(LAMBDA x, acc : acc + x, 0, <<5, 6, 7>>, {})
====
