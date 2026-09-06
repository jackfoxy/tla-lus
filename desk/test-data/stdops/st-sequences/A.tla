---- MODULE A ----
EXTENDS Sequences, Integers
S == <<1, 2, 3>>
L == Len(S)
LEmpty == Len(<<>>)
H == Head(S)
T == Tail(S)
Ap == Append(S, 4)
Cat == S \o <<9, 8>>
CatEmpty == <<>> \o S
Sub == SubSeq(S, 2, 3)
SubEmpty == SubSeq(S, 3, 2)
Sel == SelectSeq(S, LAMBDA x : x > 1)
SelNone == SelectSeq(S, LAMBDA x : x > 9)
SeqMem == S \in Seq(1..3)
SeqNotMem == <<4>> \in Seq(1..3)
SeqSet == Seq({1})
FcnSeq == [i \in 1..3 |-> i * i]
FcnLen == Len([i \in 1..3 |-> i])
====
