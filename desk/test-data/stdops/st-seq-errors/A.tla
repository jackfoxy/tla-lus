---- MODULE A ----
EXTENDS Sequences, Integers
HeadEmpty == Head(<<>>)
TailEmpty == Tail(<<>>)
SubOutHigh == SubSeq(<<1, 2>>, 1, 5)
SubOutLow == SubSeq(<<1, 2>>, 0, 1)
LenNotSeq == Len({1, 2})
LenString == Len("abc")
AppendNotSeq == Append({1}, 2)
CatNotSeq == <<1>> \o {2}
SelNotBool == SelectSeq(<<1, 2>>, LAMBDA x : x)
SeqNotSet == Seq(3)
====
