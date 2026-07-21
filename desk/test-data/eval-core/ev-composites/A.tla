---- MODULE A ----
EXTENDS Integers
EmptyTup == <<>>
Tup == <<1, 2, 3>>
Nest == <<<<1>>, 2>>
EmptyRec == [x |-> 1]
Rec == [a |-> 1, b |-> "two"]
Fcn == [i \in 1..3 |-> i * i]
EmptySet == {}
Set == {3, 1, 2, 1}
NestSet == {{1}, {}, {1, 2}}
====
